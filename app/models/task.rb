class Task < ActiveRecord::Base
  
  include DomainChecks
  include SortableElements::Mixins
  include ActsAsLogged
  log_changes_of 'summary', 'estimate'

  attr_accessor :suppress_parent_validation
  
  belongs_to :item
  belongs_to :sprint, :include => :backlog_elements
  has_many :task_logs # foreign key constraint was deliberetly removed
  has_many :task_users
  has_many :users, :through => :task_users, :uniq => true, :order => :login

  validates_presence_of :summary
  validates_presence_of :item, :unless => Proc.new { |task| task.suppress_parent_validation }
  validates_length_of :summary, :within => (1..255)
  validates_numericality_of :estimate, :only_integer => true

  before_update :update_changelog
  after_create :create_changelog
  before_destroy :finish_changelog

  acts_as_sortable :sortable_task
  
  accepts_nested_attributes_for :task_users

  ESTIMATE_CHOICES = (0..999).to_a 
  
  def validate
    unless ESTIMATE_CHOICES.include?(estimate)
      errors.add(:estimate, "should be in range from 0 to 999") 
    end
  end

  public

  def self.estimate_choices
    ESTIMATE_CHOICES  
  end

  def estimate_safe=(value)
    self.estimate = value
    return value if self.valid?
    self.estimate = 1 if self.errors.on(:estimate)
    self.estimate
  end

  def summary_safe=(value)
    self.summary = value
    return value if self.valid?
    self.summary = value[0..254] if self.errors.on(:summary)
    self.summary
  end

  def update_changelog
    old_estimate = Task.find(self.id).estimate
    if self.estimate != old_estimate
      log = prepare_task_log
      return unless log.sprint
      log.estimate_new = self.estimate
      log.estimate_old = old_estimate
      log.save!
    end
  end

  def create_changelog(sprint = nil)
    log = prepare_task_log
    return unless log.sprint || sprint
    log.sprint = sprint unless sprint.nil?
    log.estimate_new = self.estimate
    log.estimate_old = nil
    log.save!
  end

  def finish_changelog(sprint = nil)
    log = prepare_task_log
    return unless log.sprint || sprint
    log.sprint = sprint unless sprint.nil?
    log.estimate_new = nil
    log.estimate_old = self.estimate
    log.save!
  end

  def assign_users(users)
    users_to_unassign = self.users.reject {|u| users.include?(u) }
    ids_to_unassign = users_to_unassign.map {|u| u.id}
    assigned_user_ids = self.users.map {|u| u.id}

    # remove users no longer assigned
    self.task_users.find(:all, :conditions => {:user_id => ids_to_unassign}).each do |task_user_to_remove|
      task_user_to_remove.destroy
    end

    # assign new users
    users.each do |user_to_assign|
      unless assigned_user_ids.include?(user_to_assign.id)
        self.task_users.create(:user => user_to_assign)
      end
    end

    # reload and return
    self.users.reload
    self.users = users
  end

  def is_done
    self.estimate == 0
  end

  def self.for_cards(sprint_id)
    domain_id = Domain.current.id
    Task.find_by_sql(["SELECT t.* from tasks t 
       JOIN backlog_elements b on t.item_id = b.id 
       JOIN sprints s on b.sprint_id = s.id
       WHERE s.id = ? AND t.domain_id = ?
       ORDER BY b.position,t.position", sprint_id, domain_id])
  end
  
  private
  
  def prepare_task_log
    log = TaskLog.new
    log.task = self
    log.user = User.current
    log.timestamp = Time.current
    log.sprint = self.item(true).sprint
    
    return log
  end

end

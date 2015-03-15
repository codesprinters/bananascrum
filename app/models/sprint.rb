class Sprint < ActiveRecord::Base
  
  include DomainChecks
  include SortableElements

  include ActsAsLogged
  log_changes_of 'name', 'goals', 'from_date', 'to_date', 'sequence_number'

  class ItemWithInfiniteEstimateAssignmentError < SecurityError
  end

  class ItemFromDifferentProjectAssignmentError < SecurityError
  end

  MAX_LENGTH = 60
  CURRENT_DATE_FROM_PROJECT_SQL = "DATE(IFNULL(CONVERT_TZ(NOW(), 'UTC', projects.time_zone), CURRENT_DATE()))"
  
  has_many :items, :dependent => :destroy, :order => 'position_in_sprint ASC'
  has_many :tasks, :through => :items

  # TODO: remove this when ready
  has_many :task_logs, :order => 'timestamp ASC'
  
  belongs_to :project
  validates_presence_of :name, :from_date, :to_date, :project
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_numericality_of :sequence_number, :greater_than_or_equal_to => 0, :on => :update
  validates_uniqueness_of :sequence_number, :scope => [:project_id]

  has_many :users,
    :finder_sql => 'SELECT DISTINCT u.*
                    FROM backlog_elements bi
                         JOIN tasks t ON bi.id = t.item_id AND bi.type = \'Item\'
                         JOIN task_users tu ON t.id = tu.task_id
                         JOIN users u ON u.id = tu.user_id
                    WHERE bi.sprint_id = #{self.id}',
    :counter_sql => 'SELECT COUNT( DISTINCT tu.user_id )
                     FROM backlog_elements bi
                          JOIN tasks t ON bi.id = t.item_id AND bi.type = \'Item\'
                          JOIN task_users tu ON tu.task_id = t.id
                     WHERE bi.sprint_id = #{self.id}'

  named_scope :past, 
    :conditions => ["from_date < #{CURRENT_DATE_FROM_PROJECT_SQL} AND to_date < #{CURRENT_DATE_FROM_PROJECT_SQL}"],
    :include => [:project, {:items => :tasks}],
    :order => "sprints.to_date, backlog_elements.position_in_sprint"
  
  named_scope :ongoing,
    :conditions => ["to_date >= #{CURRENT_DATE_FROM_PROJECT_SQL} AND from_date <= #{CURRENT_DATE_FROM_PROJECT_SQL}"],
    :include => [:project, {:items => :tasks}],
    :order => "backlog_elements.position_in_sprint"

  named_scope :future,
    :conditions => ["from_date > #{CURRENT_DATE_FROM_PROJECT_SQL}"],
    :include => [:project, {:items => :tasks}],
    :order => "backlog_elements.position_in_sprint"
    
  def validate
    return unless self.project
    
    if from_date && to_date && from_date >= to_date
      errors.add(:from_date, "has to be before sprint end date")
    end

    if length and length > MAX_LENGTH
      errors.add_to_base "Sprint length has to be less than or equal #{MAX_LENGTH}."
    end
  end

  def before_validation_on_create
    return unless project

    if sequence_number.blank?
      self.sequence_number = choose_biggest_sequence_number
    end
  end

  def length
    if to_date and from_date
      to_date - from_date + 1
    else
      nil
    end
  end

  def remaining_days
    if to_date then
      (to_date - Date.current)
    else
      nil
    end
  end

  def remaining_work_days
    free_day = project.free_days || {}
    free_days_indexes = []
    remaining = 0
    tomorrow = Date.current + 1
    (tomorrow..to_date).each_with_index do |day, index|
      remaining += 1
      if free_day[day.wday.to_s] == '1'
        free_days_indexes << index 
      end
    end

    work_days = remaining  - free_days_indexes.length
    return work_days.to_i
  end

  def tasks_estimated_effort
    tasks.map(&:estimate).sum
  end

  def items_estimated_effort
    return self.items.estimated.map(&:estimate).compact.sum
  end

  # Neccessary for proper logging, tells what value should be used
  # in 'sprint_id' column of Log table
  # See Log for usage
  def sprint_for_log
    return self
  end

  # it's public as it's used from controller as well
  def choose_biggest_sequence_number
    # find the largest sequence number
    biggest_sequence_number = select_all_but_self.inject(0) do |biggest, sprint|
      # staying secure in case of nil sequence numbers
      to_compare = sprint.sequence_number.nil? ? 0 : sprint.sequence_number
      biggest > to_compare ? biggest : to_compare
    end
    # and use the subsequent to it
    return(biggest_sequence_number.nil? ? 1 : biggest_sequence_number + 1)
  end

  # used only in printing view returns total SP and task hours in a table
  def stats_for_printing
    tasks = self.tasks
    items = self.items

    stats = {}
    stats[:total_items] = items.count
    stats[:total_tasks] = tasks.count
    stats[:not_estimated_items] = items.count(:conditions => "estimate IS NULL")

    total_sp = items_estimated_effort
    stats[:total_sp] = (total_sp.round == total_sp ? total_sp.to_i : total_sp)
    stats[:total_hours] = tasks.inject(0) {|sum, task| sum + task.estimate}

    return stats
  end

  def assign_item(item, position = nil)
    Sprint.transaction do
      #return if backlog item doesn't belong to sprint's project
      unless item.project.eql? self.project
        raise Sprint::ItemFromDifferentProjectAssignmentError.new "Item #{item.user_story} and sprint #{self.name} are not in the same project"
      end
      if item.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE
        raise Sprint::ItemWithInfiniteEstimateAssignmentError.new "Unable to assign item “#{item.user_story}” to sprint. Item's estimate set to infinite."
      end

      # Append item at the end of the sprint
      item.sprint = self
      item.position_in_sprint = position
      item.save!
      project.cleanup_markers
      item.reload
    end
  end

  def participants
    self.users.map{|u| u.login.to_s}.join(', ')
  end

  def ended?
    Date.current > self.to_date
  end

  def can_be_edited_by?(user)
    self.project.can_edit_finished_sprints || user.admin? || !self.ended?
  end

  def planning_marker
    return Sprint::PlanningMarker.new(self)
  end

  protected
  def select_all_but_self
    all_but_self = Sprint.find(:all, :conditions => "project_id = #{self.project.id}")
    all_but_self.delete(self)
    all_but_self
  end

  class PlanningMarker
    def initialize(sprint)
      @sprint = sprint
    end

    def sprint_name
      @sprint.name
    end

    def effort
      @sprint.items_estimated_effort
    end

    def project
      @sprint.project
    end

    def sprint_to_date
      @sprint.to_date
    end
  end
end

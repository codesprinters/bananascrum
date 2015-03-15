class Item < BacklogElement

  INFINITY_ESTIMATE_REPRESENTATIVE = 9999.freeze

  include ActsAsLogged
  log_changes_of 'user_story', 'description', 'estimate', 'sprint_id'

  include PlanLimits
  checks_plan_using ItemsLimitChecker
  
  has_many :tasks, :dependent => :destroy, :order => "position ASC"
  has_many :users, :through => :tasks, :select => "DISTINCT users.*"
  has_many :users_who_changed_it, :through => :logs, :uniq => true, :class_name => "User", :source => :user
  has_many :clips, :dependent => :destroy
  has_many :comments, :order => "created_at ASC"

  has_many :item_tags
  has_many :tags, :through => :item_tags, :order => 'name ASC'

  named_scope :estimated, :conditions => ["estimate != ?", self::INFINITY_ESTIMATE_REPRESENTATIVE]
  named_scope :not_estimated, :conditions => "estimate IS NULL"
  named_scope :done, 
    :joins => [ "INNER JOIN tasks ON tasks.item_id = backlog_elements.id" ],
    :group => "backlog_elements.id",
    :select => "backlog_elements.*",
    :having => "SUM(tasks.estimate) = 0"
  named_scope :remaining,
    :joins => [ "LEFT JOIN tasks ON tasks.item_id = backlog_elements.id" ],
    :group => "backlog_elements.id",
    :select => "backlog_elements.*",
    :having => "SUM(tasks.estimate) > 0 OR COUNT(tasks.id) = 0"

  validates_presence_of :user_story
  validates_length_of :user_story, :within => (1..255)
  validates_numericality_of :estimate, :allow_nil => true,
    :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100,
    :unless => Proc.new { |item| item.infinity? }

  before_update :check_sprint_change

  accepts_nested_attributes_for :tasks

  def infinity?
    estimate == INFINITY_ESTIMATE_REPRESENTATIVE
  end

  def validate
    # Items on sprint can't be infinite
    if !sprint.nil? && estimate == INFINITY_ESTIMATE_REPRESENTATIVE
      errors.add(:estimate, "value can't be infinite")
    end
  end

  def user_story_safe=(value)
    self.user_story = value
    return value if self.valid?
    self.user_story = value[0..254] if self.errors.on(:user_story)
    self.user_story
  end

  def check_sprint_change
    old_sprint = Item.find(self.id).sprint
    if not self.sprint.eql?(old_sprint)
      if self.sprint.nil?
        self.tasks.each { |task| task.finish_changelog(old_sprint) }
      else
        self.tasks.each { |task| task.create_changelog(self.sprint) }
      end
    end
  end

  #TODO: change type ckecks below to named scopes
  def create_item_log
    logs.of_create.first
  end

  def update_item_log
    logs.of_update.last
  end

  # Neccessary for proper logging, of dropping item from sprint
  # See Log for usage
  def sprint_for_log
    return self.sprint if self.sprint
    if self.sprint_id_was
      return Sprint.find_by_id(self.sprint_id_was)
    end
  end

  def last_updated_by
    return nil if update_item_log.nil?
    return update_item_log.user
  end

  def log_update?
    (user_story != user_story_was) || (description != description_was) || (estimate != estimate_was)
  end

  def update?
    logs.of_update.count > 0
  end

  def self.estimate_choices
    Project.current.estimate_choices
  end

  def is_assigned
    sprint_id
  end

  def is_done
    tasks.length > 0 and tasks.all? {|t| t.estimate == 0}
  end

  def more_intish_estimate
    est = self.class.readable_estimate(self.estimate)
    if est.kind_of?(BigDecimal) && est.round == est
      return est.to_i
    else
      return est
    end
  end

  def readable_description
    if self.description.nil?
      "Description not set"
    else
      self.description.strip == "" ? "Description not set" : self.description
    end
  end

  def self.readable_estimate(est)
    if est.nil?
      return "?"
    elsif est == INFINITY_ESTIMATE_REPRESENTATIVE
      return "∞"
    elsif est == est.to_i
      return est.to_i
    else
      return est
    end
  end

  def can_have_infinite_estimate?()
    return self.sprint.nil?
  end


  # TAGGING
  def add_tag(tag)
    # returns whether a new tag was created or not (this is only possible when using string/symbol as a tag)
    case tag
    when Tag
      tags << tag
      return false # obviously not a newly created tag
    when Symbol, String
      tag_name = tag.to_s
      tag = self.project.tags.find_or_initialize_by_name(tag_name)
      newly_created = tag.new_record?
      tag.save if newly_created
      tags << tag
      return newly_created
    end
  end

  def remove_tag(tag)
    tag = case tag
    when Tag
      tag
    when Symbol, String
      self.project.tags.find_by_name!(tag.to_s)
    end
    item_tag = self.item_tags.find_by_tag_id(tag.id)
    item_tag.destroy if item_tag
  end

  def tag_list
    tags.map{|t| t.name}
  end

  def self.stats_for_printing(items)
    stats = {}

    stats[:total_items] = items.count
    not_estimated = items.select { |item| item.estimate.nil? }
    stats[:not_estimated] = not_estimated.size

    # takes all estimated items, will take care with nils by compact call
    estimated = items.select { |item| item.estimate != self::INFINITY_ESTIMATE_REPRESENTATIVE}
    stats[:total_sp] = estimated.collect { |b| b.estimate }.compact.sum
    return stats
  end

  def item?
    true
  end

  def create_copy
    not_to_copy = ['id', 'user_story', 'created_at', 'updated_at']

    attributes_copy = self.attributes.reject { |k,v| not_to_copy.include?(k) }
    item = Item.new(attributes_copy)
    item.user_story = "Copy of: #{self.user_story}"
    item.save

    # copy tasks
    not_to_copy = ['id']
    self.tasks.each do |task|
      task_attributes_copy = task.attributes.reject { |k,v| not_to_copy.include?(k) }
      new_task = item.tasks.create(task_attributes_copy)
      task.task_users.each do |task_user|
        new_task.task_users.create(:user_id => task_user.user_id, :task_id => task_user.task_id)
      end
    end

    # copy comments
    self.comments.each do |comment|
      comment_attributes_copy = comment.attributes.reject { |k,v| not_to_copy.include?(k) }
      item.comments.create(comment_attributes_copy)
    end

    # copy tags
    self.tags.reverse.each do |tag|
      item.add_tag(tag)
    end

    # copy attachments
    self.clips.each do |attachment|
      attrs = attachment.attributes.reject {|k,v| ['id', 'item_id'].include?(k) }
      new_clip = item.clips.create(attrs)
      destination_dir = File.join(AppConfig.attachments_path.gsub(':rails_root', RAILS_ROOT), new_clip.id.to_s)
      FileUtils.mkdir(destination_dir)
      FileUtils.cp(attachment.file_path, new_clip.file_path)
    end

    return item
  end
  
end

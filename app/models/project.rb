class Project < ActiveRecord::Base
  include DomainChecks
  include PlanLimits

  # Base class for project exceptions
  class ProjectError < StandardError; end
  # Error thrown when record can't be deleted
  class DestroyError < ProjectError; end
    
  checks_plan_using ProjectsLimitChecker

  validates_presence_of(:presentation_name, :sprint_length, :backlog_unit, :task_unit, :csv_separator, :estimate_sequence)
  validates_length_of(:csv_separator, :is => 1)                        
  validates_format_of(:name, :with => /^[a-z0-9_\-]+$/, :message => 
      "validation failed. Codename can consist " +
      "of digits, low case alphanumerics,  '_' and '-' only.")
  validates_format_of(:calendar_key, :with => /^[a-f0-9]{32}$/)
  validates_uniqueness_of(:name, :scope => [:domain_id])
  validates_numericality_of(:sprint_length, :only_integer => true, 
    :greater_than => 0, :less_than_or_equal_to => Sprint::MAX_LENGTH)
  validates_inclusion_of :time_zone, :in => ActiveSupport::TimeZone.all.map { |tz| tz.name }
  
  before_validation_on_create :ensure_free_days_not_nil
  before_validation_on_create :ensure_visible_graphs_not_nil
  
  before_create :reset_preferences
  after_create :assign_users

  has_many :backlog_elements
  has_many :items
  has_many :planning_markers, :order => 'position ASC'
  has_many :sprints
  has_many :tasks, :through => :items
  has_many :users, :through => :role_assignments, :uniq => true, :order => :login
  has_many :viewing_users, :class_name => 'User', :foreign_key => 'active_project_id', :dependent => :nullify
  has_many :tags, :order => 'name ASC'
  has_many :impediments, :order => "id ASC"
  has_many :role_assignments
  has_many :clips, :through => :items
  has_many :juggernaut_sessions

  attr_protected :domain_id
  attr_accessor :users_to_assign

  serialize :free_days
  serialize :visible_graphs

  named_scope(:not_archived, :conditions => {:archived => false})
  named_scope(:archived, :conditions => {:archived => true})

  INFINITY_ESTIMATE_REPRESENTATIVE = 9999.freeze
  LINEAR_ESTIMATE = [nil] + (0..40).to_a + [INFINITY_ESTIMATE_REPRESENTATIVE]
  FIBONNACI_ESTIMATE = [nil, 0, 0.5, 1, 2, 3, 5, 8, 13, 20, 40, 100, INFINITY_ESTIMATE_REPRESENTATIVE]
  SQUARE_ESTIMATE = [nil, 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, INFINITY_ESTIMATE_REPRESENTATIVE]

  ESTIMATE_SEQUENCES = {
    :linear => 'Linear 0, 1, 2, 3, 4, 5 ...',
    :fibonnaci => 'Fibonnaci 0, 0.5, 1, 2, 3, 5 ...',
    :square => 'Square 0, 1, 4, 9, 16, 25 ...'
  }.freeze

  SETTINGS_LABELS = {
    :backlog_unit => "Unit used for estimating backlog items",
    :task_unit => "Unit used for estimating tasks",
    :sprint_length => "Sprint length in days",
    :csv_separator => "Separator used for CSV exports"
  }.freeze

  DEFAULT_VISIBLE_GRAPHS = { 'Burndown' => '1', 'Burnup' => '1', 'Workload' => '1', 'Items Burndown' => '1'}.freeze
  DEFAULT_FREE_DAYS = { '0' => '0', '1' => '0', '2' => '0', '3' => '0', '4' => '0', '5' => '0', '6' => '0'}.freeze
  
  #
  # Bug fix for passenger and it's weird inheritance behaviour
  #
  def self.skip_time_zone_conversion_for_attributes
    []
  end

  def self.new(*args)
    project = super(*args)
    project.calendar_key = Digest::MD5.hexdigest(rand.to_s)
    project
  end

  def to_param
    name.to_s
  end

  def ongoing_sprints
    today = Date.current
    sprints.all(:order => 'sequence_number ASC',
      :conditions => ['from_date <= ? AND to_date >= ? ', today, today])
  end

  def last_sprint_after(date)
    sprints.first(:order => 'from_date DESC', :conditions => ['from_date <= ?', date])
  end

  def first_sprint
    sprints.first(:order => 'from_date ASC')
  end

  def last_sprint
    s = ongoing_sprints
    if s.empty?
      last_sprint_after(Date.current) || first_sprint
    else
      s.last # s is sorted by sequence number
    end
  end

  # Returns suggested names for sprints to plan
  #
  # This method is used by planning markers to obtain sprint name they reflect
  # to.
  # It returns self.planning_markers.count + 1 suggested sprint names, that'll
  # be displayed on timeline view.
  # Results of counting sprints to plan names is cached. If you changed
  # number, or positions of planning markers, call
  # refresh_sprints_to_plan_names! before this method.
  def sprints_to_plan_names
    refresh_sprints_to_plan_names! if @sprints_to_plan_names.nil?
    return @sprints_to_plan_names
  end

  def refresh_sprints_to_plan_names!
    sprints_to_plan_count = planning_markers.length
    sequence_number = sprints.map { |s| s.sequence_number }.select { |sequence_number| sequence_number }.max.to_i + 1
    sprint_names = sprints_to_plan.map { |s| s.name }
    @sprints_to_plan_names = (0..sprints_to_plan_count).map { |i| sprint_names[i] or "Sprint #{sequence_number + i}" }
  end

  # Returns last planning marker, used in timeline view
  # Last marker is a special case of planning marker.
  # It displays sprint name and effort for all items on backlog, from 'eal
  # last planning marker, stored in database, to the bottom of the backlog.
  # It is because we don't allow real planning markers to be placed on last
  # position on backlog
  def last_planning_marker
    return Project::LastPlanningMarker.new(self)
  end

  def check_no_sprints_and_items
    self.sprints.empty? and self.items.empty?
  end

  def sprints_to_plan
    list = []
    list << last_sprint if last_sprint && last_sprint.items.empty?
    return list + sprints.future
  end

  def self.current
    Thread.current[:project]
  end

  def self.current=(project)
    raise "`Project` expected but `#{project.class.name}` given" unless (self === project || project.nil?)
    Thread.current[:project] = project
  end

  def self.preferred_time_zones
    europe_zones = %w[Warsaw Berlin London Dublin Rome ].map do |tzname| 
      ActiveSupport::TimeZone.new(tzname) 
    end 
    (ActiveSupport::TimeZone.us_zones + europe_zones).sort
  end

  # sets visible_graphs to devault hash with all values set to 0
  def self.visible_graphs_unselected
    hash = {}
    DEFAULT_VISIBLE_GRAPHS.each do |key, value|
      hash[key] = '0';
    end
    return hash
  end

  def estimate_choices    
    result = []
    for estimate in estimate_sequence.split(',')
      if estimate == ''
        result << nil
      else
        result << estimate.to_f
      end
    end
    return result
  end

  def estimate_sequence=(estimate)
    parsed_estimate = Project.parse_estimate(estimate)
    self[:estimate_sequence] = parsed_estimate ? parsed_estimate : estimate
  end

  def self.parse_estimate(estimate)
    case estimate.to_sym
    when :linear
      return LINEAR_ESTIMATE.join(',')
    when :fibonnaci
      return FIBONNACI_ESTIMATE.join(',')
    when :square
      return SQUARE_ESTIMATE.join(',')
    else
      return nil
    end
  end

  def estimate_presentation
    case self.estimate_sequence
    when LINEAR_ESTIMATE.join(',')
      return :linear
    when FIBONNACI_ESTIMATE.join(',')
      return :fibonnaci
    when SQUARE_ESTIMATE.join(',')
      return :square
    end    
  end

  def reset_settings!
    transaction do
      if archived?
        raise ProjectError.new("Cannot reset settings on archived project")
      end
      reset_preferences
      reset_free_days
      reset_visible_graphs
      save!
    end
  end

  def self.settings
    SETTINGS_LABELS.keys
  end

  def add_user_with_role(user, role)
    begin
      role_assignments.create!(:user => user, :role => role)
    rescue
      nil
    end
  end

  def user_has_this_role_only?(user, role_code)
    roles = self.get_user_roles(user)
    roles.size == 1 && roles.first.code == role_code
  end

  def get_user_roles(user)
    role_assignments.find(:all, :conditions => { :user_id => user }).map { |ra| ra.role }
  end

  def remove_all_users_roles(user)
    role_assignments.find(:all, :conditions => { :user_id => user }).each { |ra| ra.destroy }
  end

  def open_impediments
    impediments.find(:all, :conditions => {:is_open => true})
  end
  
  def estimated_effort
    self.items.find(:all, :conditions => ["sprint_id IS NULL AND estimate != ?", Item::INFINITY_ESTIMATE_REPRESENTATIVE]).collect { |b| b.estimate}.compact.sum
  end
  
  def not_estimated_backlog_items
    self.items.find(:all, :conditions => { :sprint_id => nil, :estimate => nil }, :include => [ :tasks, :tags]).size
  end

  def average_velocity
    num = self.sprints.past.count
    return "unknown" if num == 0
    sum = self.sprints.past.map(&:items_estimated_effort).sum.to_f / num
    return sprintf("%3.1f #{self.backlog_unit}", sum)
  end

  def sprint_calendar
    require 'icalendar'
    cal = Icalendar::Calendar.new

    self.sprints.each do |sprint|
      cal.event do
        dtstart sprint.from_date
        dtend sprint.to_date + 1.day
        summary "Sprint #{sprint.sequence_number}: #{sprint.name}"
        description sprint.goals
      end
    end

    cal
  end
  
  # returns archived projects only if user is an admin
  def self.find_all_for(user)
    return nil if user.nil?
    if user.admin?
      return user.projects
    else
      return user.projects.reject{|p| p.archived?}
    end
  end
  
  def display_timezone
    ActiveSupport::TimeZone[time_zone].to_s if time_zone
  end

  def users_logins
    users.map(&:login)
  end

  def team_members
    users.find(:all, :joins => "join roles on role_assignments.role_id = roles.id",
      :conditions => {"roles.code" => "team_member", "blocked" => "false"})
  end

  # Permanently deletes project and all its related components
  def purge!
    Project.transaction do
      clips = self.clips.map { |c| c }
      delete
      clips.each do |clip|
        begin
          clip.destroy_attached_files
        rescue => e
          logger.error("Failed to delete file: #{e.message}")
        end
      end
    end
  rescue => e
    raise Project::DestroyError.new(e.message)
  end

  # Removes consecutive planning markers, so the state is always clean
  # FIXME: This is not very efficient, due to callbacks
  def cleanup_markers
    Project.transaction do
      idx = 0
      previous_marker = false
      backlog_elements.not_assigned.each do |elem|
        if elem.type == 'PlanningMarker' and (idx == 0 or previous_marker)
          elem.destroy
          previous_marker = true
        else
          previous_marker = elem.type == 'PlanningMarker'
        end
        idx += 1
      end
      count = backlog_elements.not_assigned.count
      if count > 0 and backlog_elements.not_assigned[-1].attributes[:type] == 'PlanningMarker'
        backlog_elements.not_assigned[-1].destroy
      end
    end
  end

  # Calculations

  def self.with_at_least_sprints(date, sprints = 5)
    sql = %q[
      SELECT COUNT(*) FROM (
        SELECT p.id
        FROM projects AS p
        JOIN sprints s ON s.project_id = p.id
        WHERE p.created_at <= :date
          AND s.created_at <= :date
        GROUP BY p.id
        HAVING COUNT(s.id) > :sprints
      ) projects_with_sprints
    ]
    count_by_sql [sql, {:date => date, :sprints => sprints}]
  end

  def self.with_active_sprint(date)
    sql = %q[
      SELECT COUNT(*) FROM (
        SELECT p.id
        FROM projects AS p
        JOIN sprints s ON s.project_id = p.id
        WHERE p.created_at <= :date
          AND s.from_date <= :date
          AND s.to_date >= :date
        GROUP BY p.id
        HAVING COUNT(s.id) >= 1
      ) projects_with_sprints
    ]
    count_by_sql [sql, {:date => date}]
  end

  # retrieves keys of currently selected graphs
  def selected_visible_graphs_keys
    graphs_hash = self.visible_graphs.blank? ? DEFAULT_VISIBLE_GRAPHS : self.visible_graphs
    keys = []
    graphs_hash.each do |key, value|
      if value.to_i == 1
        keys << key
      end
    end
    return keys
  end

  def has_any_graph_selected?
    DEFAULT_VISIBLE_GRAPHS.merge(ensure_visible_graphs_not_nil).any? {|key, value| value.to_i == 1}
  end

  def graph_visible?(graph)
    fetched_val = self.ensure_visible_graphs_not_nil.fetch(graph, 0)
    return fetched_val.to_i == 1
  end

  protected
  
  def assign_users
    
    return unless self.users_to_assign
    users_to_assign.each do |key, value|
      role = Role.find_by_code(key)
      if role
        value.keys.each do |login|
          user = self.domain.users.find(:first, :conditions =>  { :login => login })
          self.add_user_with_role(user, role)
        end
      end
    end
  end

  def ensure_free_days_not_nil
    self.free_days ||= DEFAULT_FREE_DAYS
  end

  def ensure_visible_graphs_not_nil
    self.visible_graphs ||= DEFAULT_VISIBLE_GRAPHS
  end

  def reset_preferences
    self.class.settings.each do |sett|
      default = Project.columns_hash[sett.to_s].default
      self[sett] = default
    end
    self.estimate_sequence = FIBONNACI_ESTIMATE.join(',')
  end
  
  def reset_free_days
    self.free_days = DEFAULT_FREE_DAYS
  end

  def reset_visible_graphs
    self.visible_graphs = DEFAULT_VISIBLE_GRAPHS
  end

  class LastPlanningMarker
    def initialize(project)
      @project = project
    end

    def sprint_name
      return @project.sprints_to_plan_names.last || "Sprint"
    end

    def effort
      effort = 0
      @project.backlog_elements.not_assigned.reverse_each do |e|
        break if e.type == 'PlanningMarker'
        effort += (e.estimate.nil? or e.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE) ? 0 : e.estimate
      end
      return effort
    end

    def project
      return @project
    end

    def sprint_to_date
      assosiated_sprint = project.sprints_to_plan[project.planning_markers.length]
      return assosiated_sprint.nil? ? nil : assosiated_sprint.to_date
    end
  end


end

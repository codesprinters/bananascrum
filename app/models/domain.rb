class Domain < ActiveRecord::Base

  SUBDOMAIN_INFO = "www"
  RESERVED = ["admin", SUBDOMAIN_INFO, "cthulhu", "siteadmin"].freeze
  NAME_NOT_VALID_MSG = "validation failed. Account name can consist of digits," +
    " lower-case alphanumerics and '-' only as it is used in URL's."

  has_one :license

  has_many :users, :order => 'login ASC'
  has_many :projects, :order => 'presentation_name ASC'
  has_many :items, :class_name => 'BacklogElement', :conditions => "sprint_id IS NULL"
  has_many :clips
  has_many :logs
  has_many :invoices

  named_scope :with_paid_plans, :joins => :plan, :conditions => ['plans.price > 0'], :readonly => false

  belongs_to :plan
  
  validates_presence_of :name
  validates_length_of :full_name, :in => 1..40
  validates_format_of :name, :with => /^([a-z0-9][a-z0-9\-_]*[a-z0-9]|[a-z0-9])$/, :message => NAME_NOT_VALID_MSG
  validates_uniqueness_of :name, :message => "is already taken"
  validates_exclusion_of :name, :in => RESERVED, :message => "is reserved."

  before_destroy :delete_attached_files
  accepts_nested_attributes_for :users

  # Bug fix for passenger and it's weird inheritance behaviour
  def self.skip_time_zone_conversion_for_attributes
    []
  end

  def suggested_name=(suggestion)
    old_name = self.name
    self.name = suggestion
    if invalid? and errors[:name]
      self.name = old_name
    end
    errors.clear
    self.name
  end

  def self.default
    return find_by_name(AppConfig::default_domain)
  end

  def self.current
    return Thread.current[:domain]
  end

  def self.current=(domain)
    Thread.current[:domain] = domain
  end

  def self.reserved?(domain_name)
    RESERVED.include?(domain_name)
  end

  def self.taken?(domain_name)
    return false if domain_name.blank?
    return true if self.reserved?(domain_name)
    
    domain_name = domain_name.downcase
    record = Domain.find_by_name(domain_name)
    
    return !record.nil?
  end

  # Calculations

  def clips_bytes
    Clip.sum(:content_file_size, :conditions => ['domain_id = ?', id])
  end

  def self.with_at_least_users(date, users = 5)
    sql = %q[
      SELECT COUNT(*) FROM (
        SELECT d.id
        FROM domains AS d
        JOIN users u ON u.domain_id = d.id
        WHERE d.created_at <= :date
          AND u.created_at <= :date
        GROUP BY d.id
        HAVING COUNT(u.id) > :users
      ) domains_with_users
    ]
    count_by_sql [sql, {:date => date, :users => users}]
  end

  def self.with_at_least_projects(date, projects = 3)
    sql = %q[
      SELECT COUNT(*) FROM (
        SELECT d.id
        FROM domains AS d
        JOIN projects p ON p.domain_id = d.id
        WHERE d.created_at <= :date
          AND p.created_at <= :date
        GROUP BY d.id
        HAVING COUNT(p.id) >= :projects
      ) domains_with_projects
    ]
    count_by_sql [sql, {:date => date, :projects => projects}]
  end

  def self.inactive_domains(max_last_login)
    sql = %q[
      SELECT COUNT(*) FROM (
        SELECT d.id
        FROM domains AS d
        JOIN users u ON u.domain_id = d.id
        GROUP BY d.id
        HAVING MAX(u.last_login) <= :max_last_login
      ) inactive_domains
    ]
    count_by_sql [sql, {:max_last_login => max_last_login}] 
  end

  def self.all_at_date(date)
    count(:conditions => ["created_at <= ?", date])
  end

  protected

  def delete_attached_files
    clips.each do |clip|
      begin
        clip.destroy_attached_files 
      rescue => e
        logger.error("Failed to delete file: #{e.message}")
      end
    end
  end

end

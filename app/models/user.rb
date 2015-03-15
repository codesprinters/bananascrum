require 'digest/sha1'

class User < ActiveRecord::Base
  include DomainChecks

  PREFERRED_DATE_FORMATS = {'YYYY-MM-DD' => '%Y-%m-%d',
    'DD-MM-YYYY' => '%d-%m-%Y',
    'YYYY.MM.DD' => '%Y.%m.%d',
    'DD.MM.YYYY' => '%d.%m.%Y',
    'MM/DD/YYYY' => '%m/%d/%Y',
    'MM/DD/YY' => '%m/%d/%y',
    'DD/MM/YYYY' => '%d/%m/%Y',
    'DD/MM/YY' => '%d/%m/%y',
  }.freeze

  has_one :customer
  has_many :user_activations, :dependent => :destroy
  has_many :tasks, :through => :task_users
  has_many :task_users
  has_many :role_assignments, :dependent => :destroy
  has_many :projects, :through => :role_assignments, :uniq => true,
    :order => :presentation_name, :conditions => "archived = 0"
  has_many :logs
  has_many :impediment_logs
  has_many :juggernaut_sessions
  has_many :invoices
  has_many :comments, :dependent => :destroy
  
  # intentional use of DISTINCT do not change to UNIQUE
  has_many :items, :through => :tasks, :select => "DISTINCT backlog_elements.*"
  belongs_to :active_project, :class_name => "Project"
  belongs_to :theme

  validates_presence_of :login, :first_name, :last_name, :email_address
  validates_uniqueness_of :login, :scope => [:domain_id]
  validates_confirmation_of :user_password
  validates_format_of :email_address, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_length_of :login, :within => 3..40

  # 'if' is to prevent of checking this condition on creating new users by admin.
  # but only during account (domain) registration
  validates_acceptance_of :terms_of_use, :accept => true, :if => :registration?

  before_destroy :ensure_no_child_rows
  before_destroy :ensure_no_logs
  before_destroy :ensure_no_impediment_logs
  before_destroy :ensure_not_deleting_ourself
  
  before_validation {|user| user.blocked = false if user.blocked.nil?; true}

  attr_accessor :password_changed, :user_password_confirmation, :old_password
  attr_accessor :send_email
  attr_accessor :note_for_user
  attr_accessible :first_name, :last_name, :email_address, :like_spam,
    :active_project, :active_project_id, :new_offers, :service_updates, :last_news_read_date, :theme_id, :date_format_preference

  # alias for accessing projects the user is really assigned to; original method is overriden in Admin model
  alias_method :assigned_projects, :projects

  named_scope(:not_blocked, :conditions => { :blocked => false })
  named_scope(:blocked, :conditions => { :blocked => true })
  named_scope(:admins, :conditions => {:type => "Admin"})

  def admin?
    return self[:type] == 'Admin'
  end

  def registration=(value)
    @registration = value
  end

  def registration?
    @registration
  end

  def validate
    if password_changed 
      if user_password.blank? 
        errors.add(:user_password, "can't be blank")
      else
        if user_password.length < 5 then
          errors.add(:user_password, "should be at least 5 characters long")
        end
      end
    end
  end

  def self.authenticate(login, password)
    user = Domain.current.users.find_by_login(login) unless Domain.current.nil?
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.password != expected_password
        user = nil
      end
    end
    user
  end

  def self.generate_password
    source_characters = "0124356789abcdefghijklmnoprstuvwxyz_"
    password = ""
    1.upto(8) { password += source_characters[rand(source_characters.length),1] }
    return password
  end

  # 'user_password' is a virtual attribute

  def user_password
    @user_password
  end

  def user_password=(pwd)
    @user_password = pwd
    @password_changed = true
    return if pwd.blank?
    create_new_salt
    self.password = User.encrypted_password(pwd, self.salt)
  end

  def self.is_current?(user)
    return user.class.current == user
  end

  def self.current
    return Thread.current[:user]
  end

  def self.current=(user)
    raise "`User` expected but `#{user.class.name}` given" unless (self === user || user.nil?)
    Thread.current[:user] = user
  end

  private

  
  def self.encrypted_password(password, salt)
    return nil if salt.blank?
    return nil if password.blank?
    string_to_hash = password + "csrocks" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end

  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end

  def ensure_not_deleting_ourself
    if self == User.current
      self.errors.add_to_base("Cannot delete yourself!")
      return false
    end
  end

  def ensure_no_child_rows
    unless tasks(true).empty?
      self.errors.add_to_base("Cannot delete user with tasks assigned! Consider blocking the user instead.")
      return false 
    end
  end

  def ensure_no_logs
    unless self.logs.blank?
      self.errors.add_to_base("Cannot delete user with item logs. Consider blocking the user instead.")
      return false 
    end
  end

  def ensure_no_impediment_logs
    unless self.impediment_logs.blank?
      self.errors.add_to_base("Cannot delete user with impediment logs. Consider blocking the user instead.")
      return false 
    end
  end

  public

  def full_name
    "#{first_name} #{last_name}"
  end

  def grant_admin_rights
    self.type = "Admin"
    self.save
  end

  def revoke_admin_rights
    self.type = nil
    self.save
  end

  def admin=(value)
    self.type = value ? 'Admin' : nil
    return self.type == 'Admin'
  end

  def new_layout
    return !theme_id.nil?
  end

  def block_user_account 
    self.blocked = true
    self.save
  end
  
  def unblock_user_account 
    self.blocked = false
    self.save
  end
  
  def switch_blocked 
    self.blocked = !self.blocked
    self.save
  end

  def prefered_date_format
    if (User::PREFERRED_DATE_FORMATS.include?(date_format_preference) && !User::PREFERRED_DATE_FORMATS[date_format_preference].blank?)
      User::PREFERRED_DATE_FORMATS[date_format_preference]
    else
      User::PREFERRED_DATE_FORMATS['YYYY-MM-DD']
    end
  end

  def js_prefered_date_format
    pref = User::PREFERRED_DATE_FORMATS.invert[prefered_date_format]
    pref.nil? ? 'yyyy-mm-dd' : pref.downcase
  end

  def reset_password
    user_activation = self.user_activations.create(:reset_pwd => true)
    user_activation.domain = self.domain unless user_activation.domain
    user_activation.save!
    
    Notifier.deliver_reset_password(self, user_activation.key)
  end
end

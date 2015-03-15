class Impediment < ActiveRecord::Base
  
  include DomainChecks
  
  belongs_to :project
  has_many :impediment_logs, :order => 'created_at DESC'

  validates_presence_of :project
  validates_presence_of :summary

  after_create :log_create

  def creator
    return nil if first_log.nil?
    return first_log.user
  end

  def creation_date
    return nil if first_log.nil?
    return first_log.created_at
    return first_log.created_at.to_date if first_log.created_at
  end

  # log.create causes change of is_open, so do not write to this field directly!

  def close(reason)
    # log.create causes change of is_open, so do not access this field directly!

    # DO NOT CHANGE THIS to impediment_logs.create
    # IT DOES NOT SET impediment relation property, so update_parent does not update this instance of the object
    # although db is updated. F*CKED lack of identity map.
    return log('closed', reason)
  end

  def reopen(reason)
    # log.create causes change of is_open, so do not access this field directly!
    return log('reopened', reason)
  end

  def comment(reason)
    return log('commented', reason)
  end

  def current_status
     self.is_open? ? "Opened" : "Closed"
  end

  def readable_description
    if self.description.nil?
      "Description not set"
    else
      self.description.strip == "" ? "Description not set" : self.description
    end
  end

  def comments
     impediment_logs.find(:all, :conditions=> "comment IS NOT NULL")
  end

  protected

  def log(action, reason)
    log = self.impediment_logs.create!(:impediment_action => ImpedimentAction.find_by_name(action), :user => User.current, :comment => reason)
    return log
  end

  def log_create
    log = self.impediment_logs.create!(:impediment_action => ImpedimentAction.find_by_name('created'), :user => User.current) 
  end

  def first_log
    log = impediment_logs.find :first,
            :select => 'impediment_logs.*',
            :joins  => 'INNER JOIN impediment_actions ia ON ia.id = impediment_logs.impediment_action_id',
            :conditions => ["ia.name = ?", 'created']
    return log.nil? ? nil : log
  end

end

class TaskUser < ActiveRecord::Base
  include DomainChecks

  include ActsAsLogged
  log_changes_of 'task_id', 'user_id', :extra_logged_fields => [ 'user_full_name', 'task_summary' ]
  
  belongs_to :user
  belongs_to :task
  has_one :item, :through => :task
  
  validates_uniqueness_of :user_id, :scope => :task_id
  
  def user_full_name
    self.user.full_name
  end
  
  def task_summary
    self.task.summary
  end
  
end

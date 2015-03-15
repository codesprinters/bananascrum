class TaskLog < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :task # shuld not be nullified on task deletion
  belongs_to :user
  belongs_to :sprint
  
  validates_presence_of :sprint

  

  def timestamp_in_zone
    self.timestamp.in_time_zone(Time.zone)
  end
end

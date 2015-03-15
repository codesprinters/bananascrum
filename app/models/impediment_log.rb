# A record of a single change to an impediment
class ImpedimentLog < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :impediment
  belongs_to :impediment_action
  belongs_to :user
  
  validates_presence_of :impediment
  validates_presence_of :impediment_action
  validates_presence_of :user
  
  def validate
    if impediment_action then
      impediment_action.validate_log(self)
    end
    
    unless user.nil?
      errors.add("Cannot add impediment to a project from other domain") if user.domain != impediment.project.domain
      if new_record?
        errors.add("Cannot add impediment to a project you take no part in") unless user.projects.include?(impediment.project)
      end
    end
  end
  
  protected
  
  # this could be normalized out, but it gets slightly ugly here.
  after_create :update_parent
  def update_parent
    status_change = self.impediment_action.open_after
    unless status_change.nil?
      impediment.is_open = status_change
      impediment.save!
    end
  end
end

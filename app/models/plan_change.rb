# This class represent logs of plan switches for domains.
class PlanChange < ActiveRecord::Base
  # FIXME: security checks disabled
  # enabling them shouldn't be a problem, but all tests that save domains
  # should be updated
  include DomainChecks 
  
#   belongs_to :domain
  belongs_to :old_plan, :class_name => "Plan"
  belongs_to :new_plan, :class_name => "Plan"
  belongs_to :user
  
  validates_presence_of :old_plan, :new_plan

  named_scope :pending, :conditions => "pending = 1"
  
  before_create :set_user_before_save
  
  def set_user_before_save
    if user.nil? 
      self.user = User.current
    end
  end

  def upgrade?
    !downgrade?
  end

  def downgrade?
    !old_plan.free? && (new_plan.free? || old_plan.price > new_plan.price)
  end
end

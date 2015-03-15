class PlanNews < ActiveRecord::Base
  belongs_to :plan
  belongs_to :news
  
  validates_presence_of :plan
  
end

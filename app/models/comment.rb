class Comment < ActiveRecord::Base
  
  include DomainChecks
  
  belongs_to :item
  belongs_to :user
  
  validates_presence_of :text
  validates_presence_of :item
  validates_presence_of :user
end

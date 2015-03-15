class Tag < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :project

  has_many :item_tags, :dependent => :destroy # callback needed for ItemSweeper to work
  has_many :items, :through => :item_tags

  attr_protected :project_id, :project

  validates_presence_of :project
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :description, :maximum => 64, :if => Proc.new { |tag| !tag.description.blank? }
end

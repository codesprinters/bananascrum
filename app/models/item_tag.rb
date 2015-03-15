class ItemTag < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :tag
  belongs_to :item

  validates_presence_of :tag
  validates_presence_of :item

  validates_uniqueness_of :tag_id, :scope => [:item_id]

  def validate
    errors.add("Cannot tag item with tag from another project") unless tag.project == item.project
  end
end

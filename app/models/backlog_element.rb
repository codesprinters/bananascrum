class BacklogElement < ActiveRecord::Base
  include DomainChecks # security checks
  include SortableElements::Mixins

  validates_presence_of :project

  belongs_to :sprint
  belongs_to :project
  belongs_to :locked_by, :class_name => "JuggernautSession"

  named_scope :locked, :conditions => ["locked_by_id IS NOT NULL"]
  named_scope :not_assigned, :conditions => "sprint_id IS NULL", :order => "position ASC"

  acts_as_sortable SortableProductBacklog
  acts_as_sortable SortableSprint

  def lock(juggernaut_session)
    self.locked_by = juggernaut_session
    save
  end

  def unlock
    self.locked_by = nil
    save
  end

  def creator
    create_item_log.try(:user)
  end

  def item?
    false
  end
end

class Log < ActiveRecord::Base
  include DomainChecks

  default_scope :order => "logs.created_at DESC", :include =>  [ :fields, :user, :task ]
  named_scope :not_task_updates, :conditions => [ "NOT (logable_type='Task' AND action='update' AND log_fields.name='estimate')" ]
  named_scope :for_user, lambda { |u_id|
    { :conditions => [ "user_id = ?", u_id ] }
  }
  named_scope :not_task_estimate_updates_for_deleted_tasks, :conditions => [ "NOT (logable_type='Task' AND action='update' AND log_fields.name='estimate' AND tasks.id IS NULL)" ], :include => [ :fields, :task ]
  named_scope :not_item_assignment_for_deleted_sprints, :conditions => [ "NOT (logable_type='Item' AND action='update' AND log_fields.name='sprint_id' AND sprints.id IS NULL)" ], :include => [ :fields, :sprint]

  belongs_to :sprint
  belongs_to :item
  belongs_to :task
  belongs_to :task_user
  belongs_to :user

  has_many :fields, :class_name => 'LogField' do
    def for(field_name)
      self.select do |field|
        field.name == field_name 
      end.first
    end
  end

  ['update', 'create', 'delete'].each do |type|
    named_scope :"of_#{type}", :conditions => ["action = ?", type]
  end

end
  
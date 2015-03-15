class UserAssignmentFields < ActiveRecord::BaseWithoutTable
  attr_accessor :projects_to_assign, :roles_to_assign, :to_assign, :user
  
  attr_accessible :projects_to_assign, :roles_to_assign, :to_assign
  
  validate :validate_project_and_roles_assignment
  
  def validate_project_and_roles_assignment
    if (self.projects_to_assign.blank? && !self.roles_to_assign.blank?) || (!self.projects_to_assign.blank? && self.roles_to_assign.blank?)
      self.errors.add(:to_assign, "user to project you have to select at least one project and role")
    end
  end

  def save
    if self.projects_to_assign && self.roles_to_assign
      self.roles_to_assign.keys.each do |role_id|
        begin
          RoleAssignment.create!(:project_id => self.projects_to_assign, :role_id => role_id, :user_id => self.user.id)
        rescue
        end
      end
    end
    return true
  end
end
class RoleAssignment < ActiveRecord::Base
  
  include DomainChecks
  
  belongs_to :user
  belongs_to :project
  belongs_to :role

  validates_presence_of :project, :role
  validates_uniqueness_of :role_id, :scope => [:user_id, :project_id]
  before_destroy :cant_modify_archived_project_roles

  def validate
    if user && project && user.domain != project.domain
      errors.add "User and project have to belong to the same domain"
    end
    cant_modify_archived_project_roles
  end

  def cant_modify_archived_project_roles
    if project && project.archived?
      errors.add "You can't modify role assignments of this project as it's archived"
      false
    end
  end

end

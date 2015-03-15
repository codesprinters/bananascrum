require File.dirname(__FILE__) + '/../test_helper'

class RoleAssignmentTest < ActiveSupport::TestCase
  fixtures :roles, :users, :projects

  def setup
    super
    Domain.current = domains :code_sprinters
    @user = users(:janek)
    @project = projects(:bananorama)
    @scrum_master = roles(:scrum_master)
  end

  def teardown
    Domain.current = nil
    super
  end
  
  def test_project_deletion_with_users_assigned_to_it
    project = projects(:destroyable)
    rah = { :project => project,
            :user => @user,
            :role => @scrum_master }
    ra = RoleAssignment.new(rah) 
    assert ra.save 

    project.destroy
    assert project.frozen?
    assert_raise(ActiveRecord::RecordNotFound) { ra.reload }
  end

  def test_cant_assign_user_without_role
    assert_raise(ActiveRecord::RecordInvalid) { @project.users << @user }
  end

  def test_cross_domain_assignment
    DomainChecks.disable do
      @project = projects(:first_in_abp_domain)
      @user = users(:banana_owner)
      @role = roles(:product_owner)
    end
    
    role_assigment = RoleAssignment.new do |ra|
      ra.project = @project
      ra.user = @user
      ra.role = @role
    end
    role_assigment.save
    
    assert !role_assigment.valid?
    role_assigment.project.domain = @user.domain
    assert role_assigment.valid?
  end
  
end

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RoleAssignmentsControllerTest < ActionController::TestCase
  fixtures :roles
  should_include_check_ssl_filter

  context "Role assignments controller" do
    setup do
      DomainChecks.disable { Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain) }

      @controller = Admin::RoleAssignmentsController.new
      @project = Factory.create(:project, :domain => @domain)
      @admin = Factory.create(:admin, :domain => @domain)
      @user = Factory.create(:user, :domain => @domain, :like_spam => true)
      @role = roles(:scrum_master)
      @assignment = @user.role_assignments.create(:role => roles(:team_member), :project => @project)
      @assignments = @user.role_assignments.count
      
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @admin.id
      @request.env["HTTP_REFERER"] = '/'
    end

    route_options = {:controller => 'admin/role_assignments', :action => 'create', :project_id => 'cos'}
    should_route(:post, '/admin/projects/cos/role_assignments', route_options)

    context "on post to create" do
      setup { xhr :post, :create, :project_id => @project.name, :user_id => @user.id, :role_id => @role.id}

      before_should 'deliver notification' do
        Notifier.expects(:deliver_roles_assigment).with do |project, user|
          user.id == @user.id && project == @project
        end
      end

      should_respond_with 200
      should "assign user to one more project" do
        DomainChecks.disable do
          assert_equal @assignments + 1, @user.reload.role_assignments.count
        end
      end
    end

    context "on delete to destroy" do
      setup do
        @assignment_count = @user.role_assignments.reload.count
        @resp = xhr :delete, :destroy, :id => @assignment.id, :project_id => @project.name
      end

      before_should 'deliver withdraw notification' do
        Notifier.expects(:deliver_role_withdrawal).with do |project, user, role|
          user.id == @user.id && project == @project && role.id == @assignment.role.id
        end
      end

      should_respond_with 200
      should "unassign user with given role from project" do
        DomainChecks.disable do
          assert_equal @assignment_count - 1, @user.role_assignments.reload.count
        end
      end
    end

    context "on archived project" do
      setup do
        @project.archived = true
        @project.save!
      end
      context "creating new role assignment" do
        setup do
          xhr :post, :create, :project_id => @project.name, :user_id => @user.id, :role_id => @role.id
        end

        should_respond_with 409
        should "have same amount of assigments as it had before request" do
          DomainChecks.disable do
            assert_equal @assignments, @user.reload.role_assignments.count
          end
        end
      end

      context "removing role assignment" do
        setup do
          @assignment_count = @user.role_assignments.reload.count
          xhr :delete, :destroy, :id => @assignment.id, :project_id => @project.name
        end

        should_respond_with 409
        should "have same amount of assigments as it had before request" do
          DomainChecks.disable do
            assert_equal @assignment_count, @user.role_assignments.reload.count
          end
        end
      end

    end
  end
end

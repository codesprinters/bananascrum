require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/users_controller'

# Re-raise errors caught by the controller.
class Admin::UsersController; def rescue_action(e) raise e end; end

class Admin::UsersControllerTest < ActionController::TestCase
  fixtures :users, :domains
  should_include_check_ssl_filter

  def setup
    @domain = Domain.find_by_name(AppConfig::default_domain)
    DomainChecks.disable do
      @controller = Admin::UsersController.new
      @request = ActionController::TestRequest.new
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @response = ActionController::TestResponse.new
      @user = users(:admin)
      @user_id = users(:user_one).id
      @request.session[:user_id] = users(:admin)
    end
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    Domain.current = @domain
    assert_same_elements @domain.users.find(:all, :order => :login), assigns(:users)
  end

  def test_edit_user
    get :edit, :id => @user_id
    assert_response :redirect
    assert_match /Only xhr/, flash[:warning]

    xhr :get, :edit, :id => @user_id
    assert_response :success
  
    Domain.current = @domain
    
    assert_template 'edit'

    resp = ActiveSupport::JSON.decode(@response.body)
  end
  
  def test_create_user_with_role
    project_id = nil
    AppConfig.stubs(:send_emails).returns(true)
    DomainChecks.disable do
      project_id = projects(:bananorama).id
    end

    Digest::SHA1.stubs(:hexdigest).returns("nasza_hasza")
    Notifier.expects(:deliver_new_user).once.with do |user, key|
      (key == "nasza_hasza" && user.login == "Janek_test")
    end

    xhr :post, :create, :form => {
      :login => "Janek_test", 
      :first_name => "Jan",
      :last_name => "Kowal",
      :email_address => "a@op.pl",
      :projects_to_assign => project_id, :roles_to_assign => { roles(:scrum_master).id => '1'} }
    
                      
    Domain.current = @domain  
    user = User.find_by_login("Janek_test")
    assert_response 200
    assert_equal "User “Janek_test” was successfully created.", flash[:notice]
    assert_not_nil user
    assert !user.role_assignments.blank?
  end

  def test_create_user_with_only_role_or_project
    project_id = nil
    DomainChecks.disable do
      project_id = projects(:bananorama).id
    end

    Digest::SHA1.stubs(:hexdigest).returns("nasza_hasza")
    assert_no_difference 'User.count' do
      xhr :post, :create, :form => {
        :login => "Janek_test", 
        :first_name => "Jan",
        :last_name => "Kowal",
        :email_address => "a@op.pl",
        :projects_to_assign => project_id }
    end
    
    assert_response 409
    resp = ActiveSupport::JSON.decode(@response.body)
    assert_match /at least one project and role/, resp['html']
    
    
    
  end

  def test_create_user_and_try_to_assign_them_to_archived_project
    project_id = nil
    AppConfig.stubs(:send_emails).returns(true)
    DomainChecks.disable do
      project_id = projects(:archived_project).id
    end

    # email should be send
    Digest::SHA1.stubs(:hexdigest).returns("nasza_hasza")
    Notifier.expects(:deliver_new_user).once.with do |user, key|
      (key == "nasza_hasza" && user.login == "Janek_test2")
    end
    
    xhr :post, :create, :form => {:login => "Janek_test2", :first_name => "Jan",  :last_name => "Kowal", :email_address => "a@op.pl" , :projects_to_assign => { '1' => project_id}, :roles_to_assign => { roles(:scrum_master).id => '1' } }

    Domain.current = @domain  
    user = User.find_by_login("Janek_test2")
    assert_response 200
    assert_equal "User “Janek_test2” was created with no assigned project.", flash[:notice]
    assert_not_nil user
  end
  
  def test_create_user_without_active_project
    AppConfig.stubs(:send_emails).returns(true)
  
    xhr :post, :create, :form => {:login => "Janek_test2", 
                            :first_name => "Jan",
                            :last_name => "Kowal",
                            :email_address => "a@op.pl"
                            }

                      
    Domain.current = @domain  
    user = User.find_by_login("Janek_test2")
    assert_response 200
    assert_equal "User “Janek_test2” was created with no assigned project.", flash[:notice]
    assert_not_nil user
  end
  
  def test_new_user
    get :new

    assert_response :redirect
    assert_match /Only xhr/, flash[:warning]

    xhr :get, :new
    assert_response :success
    assert_template 'new'
  end

  def test_update_user
    user = nil
    DomainChecks.disable { user = users(:user_one) }
    assert user.email_address != "some@email.com"
    xhr :put, :update, :id => @user_id, :user => { :email_address => "some@email.com" }
    assert_response 200
    assert_equal "User was successfully updated.", flash[:notice]
    
    DomainChecks.disable { user.reload }
    assert_equal "some@email.com", user.email_address
  end

  def test_destroy
    Domain.current = users(:user_one).domain
    id = users(:unemployed).id
    xhr :post, :destroy, :id => id
    DomainChecks.disable do
      assert_response 200
      assert ! User.exists?(id)
    end

    xhr :post, :destroy, :id => @user_id
    
    DomainChecks.disable do
      assert_response 409
      #assert_equal "User was not deleted - unassign tasks first", flash[:error]
      assert User.exists?(@user_id)
    end
    Domain.current = nil
  end

  def test_impossible_to_delete_himself
    xhr :delete, :destroy, :id => @user.id
    assert_response 409
    resp = ActiveSupport::JSON.decode(@response.body)

    assert_not_nil resp['_error']
    assert_not_nil resp['_error']['message']
    assert_match /Cannot delete yourself!/, resp['_error']['message']
    
  end

  def test_update_block_status
    user = nil
    
    DomainChecks.disable do
      user = users(:unblock_user_account)
      assert !user.blocked?
    end
    
    put :block, :id => user.id, :user_blocked => '1'
    assert_response 200
    
    DomainChecks.disable do
      user = user.reload
      assert user.blocked?
      assert_equal "User account #{user.login} was successfully blocked.", flash[:notice]
    end
  end
  
  def test_update_unblock_status
    user = nil
    DomainChecks.disable do
      user = users(:block_user_account)
      assert user.blocked?
    end
    
    put :block, :id => user.id, :user_blocked => '0'
    assert_response 200
    
    DomainChecks.disable do
      user = user.reload
      assert !user.blocked?
      assert_equal "User account #{user.login} was successfully unblocked.", flash[:notice]
    end
  end

  def test_granting_admin_rights
    user = nil
    DomainChecks.disable do
      user = users(:block_user_account)
      user.admin = false
      user.save!
    end

    put :admin, :id => user.id, :user_admin => '1'
    assert_response 200

    DomainChecks.disable do
      # We have to do it this way, due to STI used
      user = User.find user.id
      assert user.admin?
    end
  end

  def test_revoking_admin_rights
    user = nil
    DomainChecks.disable do
      user = users(:block_user_account)
      user.admin = true
      user.save!
    end

    put :admin, :id => user.id, :user_admin => '0'
    assert_response 200

    DomainChecks.disable do
      # We have to do it this way, due to STI used
      user = User.find user.id
      assert !user.admin?
    end

  end

  def test_not_autorised_are_redirected
    DomainChecks.disable do
      @request.session[:user_id] = users(:janek)
    end

    post :destroy, :id => @user_id
    redirected_to_profile

    post :update, :id => @user_id, :email_address => "some@email.com"
    redirected_to_profile

    get :new
    redirected_to_profile

    get :edit, :id => @user_id
    redirected_to_profile
  end

  def test_limit_user
    AppConfig.stubs(:send_emails).returns(true)
    plan = plans(:simple_plan)
    plan.users_limit = @domain.users.count(:conditions => "blocked = 0") + 1
    plan.save!

    post :create, :form => {:login => "Kulfon_test", :first_name => "Jan", :last_name => "Kowal", :email_address => "a@op.pl"}
    assert_response :redirect

    Domain.current = @domain
    
    assert_match /Only xhr/, flash[:warning]

    user = User.find_by_login("Kulfon_test")
    assert_nil user
    
    xhr :post, :create, :form => {:login => "Kulfon_test", :first_name => "Jan", :last_name => "Kowal", :email_address => "a@op.pl"}
    assert_response :success

    xhr :post, :create, :form => {:login => "Kulfon_test", :first_name => "Jan", :last_name => "Kowal", :email_address => "a@op.pl"}
    assert_response 409
  
    assert_template :new
  end
  
  def test_creating_user_with_password_requires_password
    AppConfig.stubs(:send_emails).returns(false)
    
    xhr :post, :create, :form => {:login => "Kulfon_test", :first_name => "Jan", :last_name => "Kowal", :email_address => "a@op.pl"}
    assert_response 409
    assert_select_on_envelope '.field-with-errors' do
      assert_select 'input', :id => "form-user-password"
    end
  end
  
  def test_creating_user_with_password
    AppConfig.stubs(:send_emails).returns(false)
    
    xhr :post, :create, :form => {:login => "Kulfon_test", :first_name => "Jan", :last_name => "Kowal", :email_address => "a@op.pl", :user_password => 'password', :user_password_confirmation => 'password'}
    assert_response 200
    Domain.current = @domain
    user = @domain.users.find_by_login 'Kulfon_test'
    
    assert_not_nil user
    assert User.authenticate('Kulfon_test', 'password')
  end

  protected
  # helper method used above
  def redirected_to_profile
    assert_response :redirect
    assert_redirected_to edit_profile_url
    assert_equal false, flash[:warning].blank?
  end

end

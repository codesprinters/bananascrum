require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../time_helper'

require 'profiles_controller'

# Re-raise errors caught by the controller.
class ProfilesController; def rescue_action(e) raise e end; end

class ProfilesControllerTest < ActionController::TestCase
  fixtures :users, :user_activations, :domains
  should_include_check_ssl_filter

  def setup
    super
    DomainChecks.disable do
      @controller = ProfilesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @user = users(:user_one)
    end
  end
  
  def teardown
    Domain.current = nil
  end
  
  def test_index
    @request.session[:user_id] = DomainChecks.disable{users(:admin)}
    User.current = DomainChecks.disable{users(:admin)}
    assert_not_nil(User.current)
    get :edit
    assert_response :success

    @request.session[:user_id] = DomainChecks.disable{users(:developer_of_second_only)}
    get :edit
    assert_response :success
  end

  def test_update
    @user  = DomainChecks.disable {users(:admin)}
    Domain.current = @user.domain
    @request.session[:user_id] = @user.id

    post :update, :user => {  :email_address => "some@email.com" }
    assert_response :redirect
    assert_equal 'Your profile was successfully updated.', flash[:notice]
    Domain.current = @user.domain
    assert_equal "some@email.com", @user.reload.email_address
  end

  def test_show_users_profile
    @request.session[:user_id] = DomainChecks.disable {users(:banana_team)}
    get :edit
    
    assert_response :success # these users are in differen projects but user_one is an admin
    # so he should be able to see user's two profile
    @request.session[:user_id] = DomainChecks.disable {users(:user_one)}
    get :edit
    assert_response :success
  end

  def test_setting_prefered_date_format
      @user = DomainChecks.disable {users(:banana_team)}
      @request.session[:user_id] = @user.id
      assert_equal("YYYY-MM-DD", @user.date_format_preference)
      post :update, :user => {:date_format_preference => "MM-DD-YYYY"}
      assert_match(/Your profile was successfully updated/, flash[:notice])
      DomainChecks.disable do
        @user.reload
      end
      assert_equal("MM-DD-YYYY", @user.date_format_preference)
      assert_response :redirect
  end
  
end

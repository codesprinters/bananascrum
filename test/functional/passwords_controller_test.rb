require File.dirname(__FILE__) + '/../test_helper'

require 'passwords_controller'

class PasswordsControllerTest < ActionController::TestCase
  fixtures :users, :user_activations, :domains
  should_include_check_ssl_filter

  def setup
    super
    DomainChecks.disable do
      @controller = PasswordsController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      @domain = Domain.find_by_name(AppConfig::default_domain)
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @user = users(:user_one)
    end
  end  

  def test_new_password
    user = DomainChecks.disable { users(:admin) }
    ua_count = DomainChecks.disable { user.user_activations(true).count }
    ka = DomainChecks.disable { user_activations(:password_to_reset) }
   
    post :create, :key => ka.key, :user => {:user_password => 'some_pwd', :user_password_confirmation => 'some_pwd'}
    assert_redirected_to(new_session_url)
    ua_count_new = DomainChecks.disable {user.user_activations(true).count}
    assert_response :redirect
    assert_equal ua_count - 1, ua_count_new
    assert_not_nil assigns["user"]
    assert_equal assigns["user"].password, User.encrypted_password("some_pwd", assigns["user"].salt)
  end

  def test_new_wrong_key
    u = DomainChecks.disable {users(:admin)}
    ua_count = DomainChecks.disable {u.user_activations(true).count}

    post :create, :key => 'Hack_it_all', :user => {:user_password => 'some_pwd', :user_password_confirmation => 'some_pwd'}
    ua_count_new = DomainChecks.disable {u.user_activations(true).count}

    assert_equal ua_count, ua_count_new    
    assert_nil assigns["user"]
    assert_template "new"
    assert_equal "Invalid activation code. Please make sure you have pasted it correctly.", flash[:error]

    assert_select 'div.field-with-errors' do
      assert_select 'input[name=key]'
    end

    assert_match /key is invalid/i, @response.body
  end

  context 'update password' do
      
    setup do
      @user = DomainChecks.disable {users(:admin)}
      @request.session[:user_id] = @user.id
    end
       
    should 'successfuly change with correct old password ' do
      put :update, :user => {:user_password => 'some_pwd', :user_password_confirmation => 'some_pwd', :old_password => 'test'}
    
      assert_response :redirect
      assert_redirected_to(edit_profile_path)
      Domain.current = @user.domain
      assert User.authenticate(@user.login, 'some_pwd')
      
      assert_equal 'Password updated successfully.', flash[:notice]    
    end

    should 'prevent change of password for incorrect password' do
      put :update, :user => {:user_password => 'some_pwd', :user_password_confirmation => 'some_pwd', :old_password => 'incorrect password'}
      assert_response 200
      assert_select 'div.field-with-errors' do
        assert_select 'input#user_old_password'
      end

      assert_match /Old password is incorrect/, @response.body
      Domain.current = @user.domain
      assert User.authenticate(@user.login, 'test')
    end

    should 'prevent change for correct old password and not matching confirmation' do
      put :update, :user => {:user_password => 'some_pwd', :user_password_confirmation => 'somethind else', :old_password => 'test'}
      assert_response 200
      assert_select 'div.field-with-errors' do
        assert_select 'input#user_user_password'
      end

      assert_match /User password doesn't match confirmation/, @response.body
      Domain.current = @user.domain
      assert User.authenticate(@user.login, 'test')
      
    end
  end
  
  def test_reset_for_nil_user
    post :reset, :login => 'some unknown login'
    assert_response 409
    assert_match /Unknown login/, @response.body
  end

  def test_reset_for_active_user
    user = DomainChecks.disable{users(:admin)}
    assert user.active?
    post :reset, :login => user.login
    assert_redirected_to(new_session_url)
    assert flash[:notice].starts_with?("Activation link to reset password sent to email.")
  end
  
  def test_do_reset_for_blocked_user
    user = DomainChecks.disable{users(:block_user_account)}
    assert user.blocked?
    post :reset, :login => user.login
    assert_response 409
    assert_match /is blocked. Contact your domain admin./, @response.body 
  end

end

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PasswordsControllerTest < ActionController::TestCase
  fixtures :all

  should_include_check_ssl_filter
  should_route(:post, '/admin/users/1/password/reset', :action => 'reset', :user_id => 1)

  context 'In PasswordsController' do
    setup do
      DomainChecks.disable do
        Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
        @user = users(:admin)
        @request.host = @domain.name + "." + AppConfig.banana_domain
        @request.session[:user_id] = @user.id
      end
    end

    context 'posting :reset' do
      setup do
        @user = users(:user_two)
        Digest::SHA1.stubs(:hexdigest).returns("nasza_hasza")
        Notifier.expects(:deliver_admin_reset_password).once.with do |user, key|
          (key == "nasza_hasza" && user.login == @user.login)
        end
        post('reset', :user_id => @user.id)
      end

      should_respond_with 200
      should_assign_to(:user) { @user }
    end

    context 'get to :new' do
      setup { get :new, :user_id => @user.id }
      
      should_respond_with(:success)
      should 'return form in envelope' do
        assert_select_on_envelope 'form', :class => /new-password/ do
          assert_select 'input', :id => 'user_user_password'
        end
      end
    end

    context 'post on :create' do
      setup do 
        @action = proc { xhr :post, :create, @params } 
        @params = { :user_id => @user.id }
      end
      
      context 'with valid params' do
        setup do
          @params[:user] = {
            :user_password => 'new password',
            :user_password_confirmation => 'new password'
          }
        end
        
        call_action_under_test do
          should_respond_with(:success)
          should 'change user password' do
            assert User.authenticate(@user.login, 'new password')
          end
        end
      end
      
      context 'with params missing' do
        call_action_under_test do
          should_respond_with(409)
          should 'render form with error' do
            assert_select_on_envelope 'form.new-password' do
              assert_select 'div.field-with-errors' do
                assert_select 'input', :id => 'user_user_password'
              end
            end
          end
        end
      end
    end

  end

end

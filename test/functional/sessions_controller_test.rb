require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
  should_include_check_ssl_filter
  should_redirect_to_https_protocol_if_enabled
  
  context "User" do
    setup do
      DomainChecks.disable do
        Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
        @user = Factory.create(:user, :domain => @domain)
        User.current = @user
        
        @project = Factory.create(:project, :domain => @domain)
        @sprint = Factory.create(:sprint, :domain => @domain, :project => @project)
      end

      @request.host = @domain.name + "." + AppConfig.banana_domain
    end

    context "on GET to :new" do
      setup { get :new }
      should_respond_with :success
      should_render_template 'new'
    end

    context "on POST to :create" do

      context 'admin user' do
        setup { @admin = Factory.create(:admin, :domain => @domain) }

        context "with valid active_project" do
          setup do
            @role = Role.find :first
            @project.add_user_with_role(@admin, @role)
            @admin.active_project = @project
            @admin.save!
            @last_sprint = @project.last_sprint
            post :create, :login => @admin.login, :password => "password"
          end

          should "be assigned to project" do
            Domain.current = @domain
            assert !@project.get_user_roles(@admin).empty?
          end

          should_respond_with :redirect
          should_redirect_to ("project last sprint page") { project_sprint_path(@project, @last_sprint) }
        end

        context "with desired url" do
          setup do
            @return_to = 'http://test.bananascrum/some_path'
            session[:return_to] = @return_to
            post :create, :login => @admin.login, :password => "password"
          end

          should_respond_with :redirect
          should_redirect_to("desired url") { @return_to }
        end

      end

      context "with valid password" do
        setup do
          @user.active_project = @project
          post :create, :login => @user.login, :password => "password"
        end

        should_respond_with :redirect
        should "login successfuly" do
          assert_equal @user.id, session[:user_id]
          assert_equal "Logged in successfully", flash[:notice]
        end
      end

      context "without password" do
        setup { post :create, :login => @user.login, :password => nil }

        should "not login" do
          assert_redirected_to(new_session_url)
          assert_equal "Login failed" , flash[:error]
        end
      end

      context "with invalid password" do
        setup { post :create, :login => @user.login, :password => "toniejestnajlepszehaslo" }
        
        should "not login" do
          assert_redirected_to(new_session_url)
          assert_equal "Login failed" , flash[:error]
        end
      end

      context "without active project" do
        setup do
          @user = Factory.create(:user, :domain => @domain)
          post :create, :login => @user.login, :password => "password"
        end
        should "be redirected to projects page" do
          assert_response :redirect
          assert_redirected_to :controller => :projects
          assert_equal 'Logged in successfully', flash[:notice]
        end
      end

      context "by a blocked user" do
        setup do
          DomainChecks.disable do
            @user = Factory.create(:user, :domain => @domain, :blocked => true)
            post :create, :login => @user.login, :password => "password"
          end
        end
        should_redirect_to("login form") { new_session_url }
        should "be redirected to login form" do
          assert @user.blocked?
          assert_equal "Your account has been blocked. Please contact your domain administrator", flash[:error]
        end
      end

      context "by an inactive user" do
        setup do
          @user = Factory.create(:user, :domain => @domain, :active => false)
          post :create, :login => @user.login, :password => "password"
        end
        should_redirect_to("login form") { new_session_url }
        should "be redirected to login form" do
          assert_equal "You must activate your account first", flash[:error]
        end
      end
    end

    context "on DELETE to :destroy" do
      setup do
        @request.session[:user_id] = @user.id
        delete :destroy
      end
      should_respond_with :redirect
      should_redirect_to("login screen") { new_session_url }
      should "log user out" do
        assert !User.current
        assert_match /You have been logged out/, flash[:notice]
        assert_nil session[:user_id]
      end
    end
  end

end

require File.dirname(__FILE__) + '/../test_helper'
require 'admin_panel_controller'

# Re-raise errors caught by the controller.
class AdminPanelController; def rescue_action(e) raise e end; end

class AdminPanelControllerTest < ActionController::TestCase
  should_include_check_ssl_filter

  def test_index
    get :index
    assert_response :redirect
  end

  context "AdminPanel controller's" do
    setup do
      DomainChecks.disable do
        Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
        @user = Factory.create(:admin, :domain => @domain)
      end
  
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @user[:id]
    end
  
    context "on GET to index" do
      setup { get :index }
      should_respond_with :success
    end
  end

end


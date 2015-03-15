require File.dirname(__FILE__) + '/../test_helper'

class CalendarsControllerTest < ActionController::TestCase
  context "Calendar resource should have a proper route" do
    route_options = {:project_id => "cos", :controller => "calendars", :action => "show"}
    should_route :get, "/projects/cos/calendar", route_options
  end

  context "Project calendar" do
    setup do
      DomainChecks.disable do
        Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
        @project = Factory.create(:project, :domain => @domain)
        @user = Factory.create(:user, :domain => @domain)
      end
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @user[:id]
    end

    context "shouldn't be accessible" do
      context "without a valid key" do
        setup do
          get :show, :project_id => @project.name, :key => "ziaziazia"
        end
        should_redirect_to("sprint pags"){ project_sprints_url(@project) }
        should_set_the_flash_to "Invalid calendar key"
      end
      context "without a key att all" do
        setup do
          get :show, :project_id => @project.name
        end
      end
    end

    context "should be accessible with a valid key" do
      setup do
        get :show, :project_id => @project.name, :key => @project.calendar_key
      end
      should_respond_with :success
      should_assign_to :calendar
      should_not_set_the_flash
    end
  end
end

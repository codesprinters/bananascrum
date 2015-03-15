require File.dirname(__FILE__) + '/../test_helper'

class NamedRoutesTest < ActionController::TestCase
  include ActionController::UrlWriter
  default_url_options[:host] = 'cs.localhost'

  def setup
    DomainChecks.disable do
      @project = projects(:bananorama)
      @controller = ApplicationController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
    end
  end

  def test_root_url
    route_options = {:controller => 'sessions', :action => 'redirect_to_active_project'}
    assert_routing('/', route_options)
  end

  def test_login_url
    login_route_options = {:controller => 'sessions', :action => 'new'}
    assert_routing(login_path(), login_route_options)
  end

  def test_logout_url
    logout_route_options = {:controller => 'sessions', :action => 'destroy'}
    assert_routing(logout_path(), logout_route_options)
  end

  def test_admin_panel_url
    admin_panel_route_options = {:controller => 'admin_panel', :action => 'index'}
    assert_routing(admin_panel_path(), admin_panel_route_options)
  end

  def test_project_url
    project_route_options = {:controller => 'items', :action => 'redirect_to_list', :project_id => @project.name}
    assert_routing project_path(@project), project_route_options
  end

  def test_profile_url
    profile_route_options = {:action=>"show", :controller=>"profiles"}
    assert_routing profile_path, profile_route_options
  end

  def test_project_sprints_url
    project_sprints_options = {:action=>"index", :controller=>"sprints", :project_id => @project.name}
    assert_routing project_sprints_path(@project.name), project_sprints_options
  end

  def test_project_sprint_url
    project_sprint_options = {:action=>"show", :controller=>"sprints", :project_id => @project.name, :id => "1"}
    assert_routing project_sprint_path(@project, "1"), project_sprint_options
  end

  def test_project_items_url
    project_items_options = {:action=>"index", :controller=>"items", :project_id => @project.name}
    assert_routing project_items_path(@project), project_items_options
  end

  def test_project_tasks_url
    project_tasks_options = {:action=>"index", :controller=>"tasks", :project_id => @project.name}
    assert_routing project_tasks_path(@project), project_tasks_options
  end

  def test_project_task_url
    project_task_options = {:action=>"show", :controller=>"tasks", :project_id => @project.name, :id => "1"}
    assert_routing project_task_path(@project, "1"), project_task_options
  end
end

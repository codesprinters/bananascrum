require File.dirname(__FILE__) + '/../test_helper'

class RoutesTest < ActionController::TestCase
  
  context 'Named routes' do
    with_options :controller => 'sessions' do |session|
      session.should_route :get, "/", :action => 'redirect_to_active_project'
      session.should_route :get, "/login", :action => 'new'
      session.should_route :get, "/logout", :action => 'destroy'
    end

    with_options :controller => 'profiles' do |profile|
      profile.should_route :get, "/profile", :action => 'show'
    end

    should_route :get, "/projects", :controller => 'projects', :action => 'index'
    should_route :get, "/projects/cos", :controller => 'items', :action => 'redirect_to_list', :project_id => 'cos'
    should_route :get, "/admin", :controller => 'admin_panel', :action => 'index'
  end

  context 'Project' do
    context 'project routes' do
      route_options = {:id => 'cos', :controller => 'admin/projects', :action => 'archive'}
      should_route :put, "/admin/projects/cos/archive", route_options
    end

    context 'backlog routes' do
      defaults = {:controller => 'items', :project_id => 'cos'}
      should_route :post, "/projects/cos/backlog/sort", defaults.merge(:action => 'sort')
      should_route :get, "/projects/cos/backlog/export_to_csv", defaults.merge(:action => 'export_to_csv')
      should_route :post, "/projects/cos/backlog/import_csv", defaults.merge(:action => 'import_csv')
      should_route :get, "/projects/cos/backlog/import_csv_from_file", defaults.merge(:action => 'import_csv_from_file')
    end

    context 'sprint routes' do
      defaults = {:controller => 'sprints', :project_id => 'cos'}
      should_route :get, "/projects/cos/sprints", defaults.merge(:action => 'index')
      should_route :get, "/projects/cos/sprints/1/plan", defaults.merge(:action => 'plan', :id => 1)
      should_route :post, "/projects/cos/sprints/1/sort", defaults.merge(:action => 'sort', :id => 1)
      should_route(:get, "/projects/cos/sprints/new", defaults.merge(:action => 'new'))
      should_route(:get, "/projects/cos/sprints/1/edit", defaults.merge(:action => 'edit', :id => 1))
      should_route(:get, "/projects/cos/sprints/1", defaults.merge(:action => 'show', :id => 1))
    end

    context 'impediment routes' do
      defaults = {:controller => 'impediments', :project_id => 'cos'}
      members = {
        :create_comment => :post,
        :status => :post,
        :impediment_summary => :post,
        :impediment_description => :post,
        :new_comment => :get,
        :description => :get,
        :summary => :get
      }
      members.each do |action, method|
        should_route(method,"/projects/cos/impediments/1/#{action}", defaults.merge(:action => action, :id => 1))
      end
      should_route(:get, "/projects/cos/impediments/new", defaults.merge(:action => 'new'))
      should_route(:get, "/projects/cos/impediments/1/edit", defaults.merge(:action => 'edit', :id => 1))
      should_route(:get, "/projects/cos/impediments/1", defaults.merge(:action => 'show', :id => 1))
    end

    context 'item routes' do
      defaults = {:controller => 'items', :project_id => 'cos'}
      members = {
        :backlog_item_description => :post,
        :backlog_item_user_story => :post,
        :backlog_item_estimate => :post,
        :item_description_text => :get,
        :lock => :post}
      
      members.each do |action, method|
        should_route(method, "/projects/cos/items/1/#{action}", defaults.merge(:action => action, :id => 1))
      end
    end
  end
end

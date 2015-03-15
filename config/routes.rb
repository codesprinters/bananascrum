ActionController::Routing::Routes.draw do |map|
  map.register_first_admin 'setup/admin', :controller => 'setup', :action => 'first_admin'
  map.change_license 'setup/license', :controller => 'setup', :action => 'change_license'

  map.with_options :controller => 'sessions' do |session|
    session.root :action => 'redirect_to_active_project'
    session.login '/login', :action => 'new'
    session.logout '/logout', :action => 'destroy'
  end

  map.project '/projects/:project_id', :controller => 'items', :action => 'redirect_to_list'

  map.admin_panel 'admin', :controller => 'admin_panel', :action => 'index'

  map.resource :index_cards,
    :controller => 'index_cards',
    :only => [:pdf, :index],
    :member => {:pdf => :post, :index => :get}

  map.resource :session,
    :controller => 'sessions',
    :only => [:new, :create, :destroy]

  map.resource :profile do |profile|
    profile.resource :password, :only => [:edit, :update, :new, :create], 
      :member => {
      :forgot => :get,
      :reset => :post}
  end

  map.theme '/themes/:slug.css',
    :controller => 'themes', :action => :show, :format => 'css',
    :conditions => { :method => :get }

  map.resources :projects, :only => [:index] do |project|
    # Project calendar
    project.resource :calendar, :controller => 'calendars', :only => :show

    # Project backlog
    project.resource :backlog, :controller => 'items',
      :member => {
      :sort => :post,
      :export_to_csv => :get,
      :import_csv => :post,
      :import_csv_from_file => :get,
      :print => :get,
      :bulk_add => [ :post, :get ]
    }

    #Project's planning markers
    project.resources :planning_markers, :only => [:create, :update, :destroy, :distribute], :collection => {
      :destroy_all => :post
    }

    # /project/:project_id/planning_markers/distribute
    project.resource :planning_markers, :only => [:distribute], :member => { :distribute => :post }

    # Project's sprints
    project.resources :sprints,
      :member => {
      :plan => :get,
      :print => :get,
      :chart => :get,
      :sort => :post,
      :remove_item_from_sprint =>  :post,
      :assign_item_to_sprint => :post
    }, :controller => 'sprints'

    # Project's impediments
    project.resources :impediments,
      :member => {
      :create_comment => :post,
      :status => :post,
      :impediment_summary => :post,
      :impediment_description => :post,
      :new_comment => :get,
      :description => :get,
      :summary => :get,
    }, :controller => 'impediments'

    # Projects's backlog items
    project.resources :items,
      :member => {
      :copy => [:get, :post],
      :backlog_item_description => :post,
      :backlog_item_user_story => :post,
      :backlog_item_estimate => :post,
      :item_description_text => :get,
      :lock => :post,
      :unlock => :post
    },
      :controller => 'items' do |items|
      items.resources :comments
      items.resources :backlog_item_tags
      items.resources :logs, :controller => :item_logs, :only => [ :show, :index ]
    end

    project.resource :timeline, :controller => :timeline, :only => [:show]

    # Project's tags
    project.resources :tags, :only => [:create, :update, :destroy]

    # Project's tasks
    project.resources :tasks,
      :member => {
      :task_estimate => :post,
      :task_summary => :post,
      :assign => :post,
      :sort => :post
    },
      :controller => "tasks"

    # Project's attachments
    project.resources :attachments,
      :controller => 'attachments'
  end

  map.dismiss_unread_news('/news/dismiss_unread', :controller => 'news', :action => 'dismiss_unread')

  map.namespace :admin do |admin|
    admin.resources :users, :except => [:show],
      :member => {
      :admin => :put,
      :block => :put
    } do |profile|
      profile.resource :password , :member => {:reset  => :post}
      profile.resource :role_assignments, :only => [:create, :destroy]
    end

    admin.resource :domain, :only => [:update, :show]
    
    admin.resources :projects, :except => [:show],
      :member => {
      :archive => :put,
      :reset_settings_to_defaults => :post,
      :estimate_settings => :post,
      :project_description_text => :post
    } do |project|
      project.resources :role_assignments, :only => [:create, :destroy]
    end
  end
  
  map.connect "/juggernaut/:action", :controller => 'juggernaut', :conditions => { :method => :post }

  # Special route to reset session to be used during Selenium testing only!
  if RAILS_ENV == "test"
    map.reset_session 'reset', :controller => 'selenium', :action => 'reset'
  end
end

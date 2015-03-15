require File.dirname(__FILE__) + '/../test_helper'
require 'sprints_controller'

# Re-raise errors caught by the controller.
class SprintsController; def rescue_action(e) raise e end; end

class SprintsControllerTest < ActionController::TestCase
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::JavaScriptHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper

  fixtures :users, :sprints, :backlog_elements, :projects, :role_assignments, :domains, :roles, :impediments, :themes

  def setup
    DomainChecks.disable do
      @controller = SprintsController.new
      @request    = ActionController::TestRequest.new

      @domain = Domain.find_by_name(AppConfig::default_domain)
      Domain.current = @domain
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @response = ActionController::TestResponse.new
      user = users(:user_one)
      User.current = user
      @request.session[:user_id] = user.id
      @sprint = sprints(:sprint_one)
      @project = projects(:bananorama)
    end
    Juggernaut.stubs(:send_to_channels) # FIXME: replace this stubs with expectations diffrent for each action
  end

  def test_showing_correct_current_profile
    ban = projects(:bananorama)
    DomainChecks.disable do
      users(:user_one).update_attribute(:theme_id, themes(:blue).id)
    end
    get :show, :project_id => @project.name, :id => @sprint
    assert_response :success
    DomainChecks.disable do
      assert_select "select#project_id" do
        assert_select "option[value=#{project_sprint_url(@project, @project.last_sprint)}]"
        assert_select 'option[selected="selected"]', @project.presentation_name
      end
    end
  end

  def test_index
    get :index, :project_id => @project.name
    assert_response :success
    assert_template 'index'
  end

  def test_index_when_no_sprints
    project = DomainChecks.disable { projects(:destroyable).name }
    get :index, :project_id => project
    assert_response 200
  end

  def test_index_when_no_sprints_and_project_is_archived
    project = DomainChecks.disable do
      project = projects(:destroyable)
      project.archived = true
      project.save!
      project.name
    end
    get :index, :project_id => project
    assert_response 200
  end

  def test_show
    get :show, :id => @sprint.id, :project_id => @project.name
    assert_response :success
    assert_template 'show'
    # is there a link to the sprints list?
    assert_tag :tag => "a",
               :attributes => {:href => project_sprints_url(@project)},
               :parent => {:tag => "li"}
  end

  def test_new
    @project = DomainChecks.disable { projects(:project_for_sprints) }

    Sprint.without_logging do
      get :new, :project_id => @project.name

      DomainChecks.disable do
        assert_response :success
        assert_template 'new'
        sprint = assigns["sprint"]
        assert_not_nil sprint
      end

      # some testing of dates

      last_sprint = nil
      DomainChecks.disable do
        last_sprint = sprints(:sprint_in_march)
        last_sprint.from_date = "2009-01-10".to_date
        last_sprint.to_date = "2009-01-15".to_date
        last_sprint.save!
      end

      get :new, :project_id => @project.name
      assert_response :success
      sprint = assigns["sprint"]
      assert_equal '2009-01-16'.to_date, sprint.from_date
      assert_equal '13', (sprint.to_date - sprint.from_date).to_s

      DomainChecks.disable do
        last_sprint.to_date = '2009-01-16' # friday
        last_sprint.save!
      end

      get :new, :project_id => @project.name
      DomainChecks.disable do
        assert_response :success
        sprint = assigns["sprint"]
        assert_equal '2009-01-19'.to_date, sprint.from_date
        assert_equal '13', (sprint.to_date - sprint.from_date).to_s

        last_sprint.to_date = '2009-01-17' # sat
        last_sprint.save!
      end

      get :new, :project_id => @project.name

      DomainChecks.disable do
        assert_response :success
        sprint = assigns["sprint"]
        assert_equal '2009-01-19'.to_date, sprint.from_date
        assert_equal '13', (sprint.to_date - sprint.from_date).to_s

        last_sprint.to_date = '2009-01-18' # sun
        last_sprint.save!
      end

      get :new, :project_id => @project.name
      DomainChecks.disable do
        assert_response :success
        sprint = assigns["sprint"]
        assert_equal '2009-01-19'.to_date, sprint.from_date
        assert_equal '13', (sprint.to_date - sprint.from_date).to_s

        last_sprint.to_date = '2009-01-19' # sun
        last_sprint.save!
      end

      get :new, :project_id => @project.name
      DomainChecks.disable do
        assert_response :success
        sprint = assigns["sprint"]
        assert_equal '2009-01-20'.to_date, sprint.from_date
        assert_equal '13', (sprint.to_date - sprint.from_date).to_s

        @project.sprints.destroy_all
      end

      get :new, :project_id => @project.name
      DomainChecks.disable do
        assert_response :success
        sprint = assigns["sprint"]
        assert_equal Time.zone.now.to_date, sprint.from_date
        assert_equal '13', (sprint.to_date - sprint.from_date).to_s
      end
    end
  end
  
  def test_new_in_archived_project
    DomainChecks.disable do
      @project.archived = true
      assert @project.save
    end
    sprint =  DomainChecks.disable{sprints(:sprint_one).clone}
    sprint = {:from_date =>  '2009-01-20'.to_date, :to_date => '2009-01-30'.to_date, :project_id => @project.name, :name => 'blabblalal', :domain => @domain}
    post :create, :sprint => sprint, :project_id => @project.name
    
    assert_response 403
  end

  def test_getting_new_page_in_archived_project
    DomainChecks.disable do
      @project.archived = true
      assert @project.save
    end
    get :new, :project_id => @project.name
    assert_response 403
  end

  def test_assign_item_to_sprint
    item = DomainChecks.disable {backlog_elements(:first)}
    post :assign_item_to_sprint, :id => @sprint[:id], :item_id => item[:id], :project_id => @project.name
    assert_response 200
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? "_flashes"
    assert json.has_key? "_removed_markers"
    assert_match /was assigned to the sprint./, json['_flashes']['notice']
  end
  
  def test_assign_item_to_given_position
    sprint = nil
    item = nil
    DomainChecks.disable do
      sprint = sprints(:sprint_with_assigned_tasks)
      item = backlog_elements(:first)
    end
    post :assign_item_to_sprint, :id => sprint[:id], :item_id => item[:id], :project_id => @project.name, :position => 1
    assert_response 200
    DomainChecks.disable do 
     item.reload
    end
    
    assert_equal 1, item.position_in_sprint
  end
  
  def test_assign_item_to_sprint_when_project_archived
    DomainChecks.disable do
      @project.archived = true
      assert @project.save
    end
    
    item = DomainChecks.disable {backlog_elements(:first)}
    
    post :assign_item_to_sprint, :id => @sprint[:id], :item_id => item[:id], :project_id => @project.name
    assert_response 403
  end

  def test_assign_sequence_number
    user = project = sprint = nil
    DomainChecks.disable do
      user = users(:admin)
      project = projects(:bananorama)
      sprint = sprints(:sprint_in_april)
    end
    @request.session[:user_id] = user.id


    get :index, :project_id => project.name
    assert_response :success

    get :edit, { :id => sprint[:id], :project_id => @project.name }
    assert_response :success
    post :update, { :id => sprint.id, :project_id => @project.name, :sprint => { :sequence_number => "8" } }
      
    assert_response 200
    sprint = DomainChecks.disable {sprint.reload}
    assert_equal(8, sprint.sequence_number)

    Domain.current = @project.domain
    another_sprint = project.sprints[1]
    post :update, { :id => another_sprint[:id], :sprint => { :sequence_number => "8" }, :project_id => @project.name }
    assert_response 409

    post :update, { :id => another_sprint[:id], :sprint => { :sequence_number => nil }, :project_id => @project.name }
    assert_response 409
  end
  
  def test_assign_infinity_item_to_sprint
    
    sprint = DomainChecks.disable {sprints(:sprint_one)}
    item = DomainChecks.disable {backlog_elements(:item_with_infinite_estimate)}
    item_id = item.id
    item_position = item.position
    num_sprint = DomainChecks.disable {sprint.items.count}
    post :assign_item_to_sprint, :id => sprint.id, :item_id => item.id, :project_id => @project.name
    assert_response 409
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? '_error'
    assert_equal "Unable to assign item “#{item.user_story}” to sprint. Item's estimate set to infinite." , json['_error']['message']
    assert_equal 'infinite_estimate_error', json['_error']['type']
    assert_equal num_sprint, sprint.items.count
    assert_equal item_id, json['item']
    assert_equal item_position, json['position']
  end

  def test_assigning_item_to_sprint_in_other_project
    item = DomainChecks.disable {backlog_elements(:first)}
    sprint = DomainChecks.disable {sprints(:sprint_in_second_project)}
    post :assign_item_to_sprint, :id => sprint[:id], :item_id => item[:id], :project_id => @project.name
    assert_response 409
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? "_error"
    assert json["_error"].has_key? "message"
    assert_equal 'assign_to_sprint_error', json['_error']['type']
    assert(! json.has_key?('item'))
    assert(! json.has_key?('position'))
    DomainChecks.disable do
      assert(!sprint.items.include?(item))
    end
  end

  def test_remove_item_from_sprint
    sprint = item = nil
    DomainChecks.disable do
      sprint = sprints(:sprint_in_april)
      item = backlog_elements(:second)
    end
        
    post :remove_item_from_sprint, :id => sprint[:id], :item_id => item[:id], :project_id => @project.name
    assert_response 200
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? "_flashes"
    assert_match /was dropped from the sprint/, json["_flashes"]["notice"]
    assert json.has_key? "_burnchart"
    
    DomainChecks.disable do
      item.reload
    end
  end
  
  def test_remove_item_from_sprint_with_backlog_position
    sprint = item = nil
    DomainChecks.disable do
      sprint = sprints(:sprint_in_april)
      item = backlog_elements(:second)
    end
    post :remove_item_from_sprint, :id => sprint[:id], :item_id => item[:id], :project_id => @project.name, :position => 5
    assert_response 200
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? 'html'
    assert json['html'].has_key? 'old'
    assert_match /Get things done too/, json['html']['old']
    
    DomainChecks.disable do 
      item.reload
    end
    assert_equal 5, item.position
  end
  
  def test_remove_item_with_no_sprint
    sprint = item = nil
    DomainChecks.disable do
      sprint = sprints(:sprint_in_april)
      item = backlog_elements(:first)
    end
    
    post :remove_item_from_sprint, :id => sprint[:id], :item_id => item[:id], :project_id => @project.name
    assert_response 409
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.has_key? "_error"
    assert_equal("This backlog item doesn't belong to any sprint",json["_error"]["message"])  
    
  end
  
  def test_destroy_sprint
    sprint = DomainChecks.disable {sprints(:sprint_to_test_task_filtering)}
    post :destroy, :id => sprint[:id], :project_id => @project.name
    assert_response 200
    assert_raise ActiveRecord::RecordNotFound do
      DomainChecks.disable {sprint.reload}
    end
  end

  def test_show_burndown_chart
    get :show, :id => @sprint[:id], :project_id => @project.name
    assert_response :success
    assert_select ".burnchart > div"
  end

  def test_chart_fullscreen
    get :chart, :id => @sprint[:id], :project_id => @project.name
    assert_response :success

    assert_equal 'layouts/chart_fullscreen', @response.layout
    assert_select ".burnchart > div"
    assert_not_nil assigns(:sprint)
    assert_not_nil assigns(:juggernaut_session)
  end

  def test_product_owner_rights
    # User with Product Owner role
    @request.session[:user_id] = DomainChecks.disable {users(:banana_owner).id}

    # Can see sprint
    get :show, :id => @sprint[:id], :project_id => @project.name
    assert_response :success

    # But cannot edit it
    get :edit, :id => @sprint[:id], :project_id => @project.name
    assert_response :redirect
  end
  
  def test_plan
    get :plan, :id => @sprint[:id], :project_id => @project.name
    assert_not_nil assigns(:items)  
    assert_not_nil assigns(:assigned_items)
  end

  def test_sort
    sprint = DomainChecks.disable { sprints(:sprint_with_assigned_tasks) }
    item = DomainChecks.disable { sprint.items[0] }
    xhr :post, :sort, :project_id => @project.name, :id => sprint[:id], :item => item[:id], :position => 2
    assert_response 200
  end

  def test_sort_bad_item
    sprint = DomainChecks.disable { sprints(:sprint_with_assigned_tasks) }
    item = DomainChecks.disable { backlog_elements(:item_with_infinite_estimate) }
    xhr :post, :sort, :project_id => @project.name, :id => sprint[:id], :item => item.id, :position => 2
    assert_response 404

  end

  def test_routes
    # index
    index_route_options = {:controller => 'sprints', :action => 'index', :project_id => @project.name}
    assert_routing("/projects/#{@project.name}/sprints", index_route_options)

    # new
    new_route_options = {:controller => 'sprints', :action => 'new', :project_id => @project.name}
    assert_routing("/projects/#{@project.name}/sprints/new", new_route_options)

    #edit
    edit_route_options = {:controller => 'sprints', :action => 'edit', :project_id => @project.name, :id => @sprint[:id].to_s}
    assert_routing("/projects/#{@project.name}/sprints/#{@sprint[:id]}/edit", edit_route_options)
  end

  context "Not an admin user" do
    setup do
      DomainChecks.disable do
        @domain = Factory.create(:domain)
        @project = Factory.create(:project, :domain => @domain)
        @sprint = Factory.create(:sprint, :domain => @domain, :project => @project)
        @user = Factory.create(:user, :domain => @domain)
        Domain.current = @domain
      end
      @request.host = @domain.name + "." + AppConfig.banana_domain
    end

    context "with active project set to the one which is archived" do
      setup do
        @user.active_project = @project
        @user.save!
        User.current = @user

        @role = Role.find_by_code "scrum_master"
        @project.add_user_with_role(@user, @role)
        @project.archived = 1;
        @project.save!
        get :show, :project_id => @project.name, :id => @project.last_sprint
      end
      should "be assigned to project" do
        Domain.current = @domain
        assert !@user.admin?
        assert @user.projects.empty?
        assert !@project.get_user_roles(@user).empty?
      end
    end
  end
end

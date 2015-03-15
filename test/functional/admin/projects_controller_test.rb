require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/projects_controller'

class Admin::ProjectsController; def rescue_action(e) raise e end; end

class Admin::ProjectsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :domains
  should_include_check_ssl_filter

  def setup
    DomainChecks.disable do
      @controller = Admin::ProjectsController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      @user = users(:user_one)
      @domain = Domain.find_by_name(AppConfig::default_domain)
      Project.current = @project = projects(:bananorama)
      @request.session[:user_id] = @user.id
      @request.host = @domain.name + "." + AppConfig.banana_domain
    end
  end

  def teardown
    Project.current = nil
  end

  context 'on POST to :create' do
    setup do
      @name = 'projectx'
      @description = "Neandertal"
      xhr :post, :create, :project => {
        :name => @name,
        :description => @description,
        :presentation_name => "The real UGh",
        :time_zone => "Santiago"
      }
    end

    should 'create project with given name' do
      DomainChecks.disable do
        project = Project.find_by_name(@name)
        assert_not_nil project
        assert_equal @description, project.description
      end
    end

    should 'respond with 200' do
      DomainChecks.disable do
        project = Project.find_by_name(@name)
        assert_response :success
      end
    end
  end

  def test_not_creating_without_time_zone
    xhr :post, :create, :project => {
      :name => "damniforgot", 
      :description => "This should not be created", 
      :presentation_name => "The real UGh"
    }

    assert_response 409
    assert_template "new"
    
    DomainChecks.disable do
      tmp = Project.find_by_name("damniforgot")
      assert tmp.nil?
    end
  end
  
  def test_new_renders_correct_mass_assignment
    xhr :get, :new
    assert_response 200
    assert_template "new"
    assert_nothing_raised do
      @json = ActiveSupport::JSON.decode(@response.body)
    end
    assert_not_nil @json['mass_assignment']
    assert_not_nil @json['mass_assignment']['team_member']
    assert_not_nil @json['mass_assignment']['scrum_master']
    assert_not_nil @json['mass_assignment']['product_owner']
    count = nil
    DomainChecks.disable { count = @domain.users.not_blocked.count }
    assert_equal count, @json['mass_assignment']['team_member'].length
    assert_equal count, @json['mass_assignment']['scrum_master'].length
    assert_equal count, @json['mass_assignment']['product_owner'].length
  end
  
  def test_invalid_create_returns_checked_assignemnt
    xhr :post, :create, :project => { 
      :users_to_assign => {
        :team_member => {
          @user.login => '1'
        },
        :scrum_master => {
          @user.login => '1'
        }
      }
    }
    assert_response 409
    assert_nothing_raised do
      @json = ActiveSupport::JSON.decode(@response.body)
    end
    assert_not_nil @json['mass_assignment']
    assert_not_nil @json['mass_assignment']['team_member']
    assert_not_nil @json['mass_assignment']['scrum_master']
    assert_not_nil @json['mass_assignment']['product_owner']
    assert_not_nil @json['mass_assignment_selected']
    assert_not_nil @json['mass_assignment_selected']['team_member']
    assert_not_nil @json['mass_assignment_selected']['scrum_master']
    assert_equal [ @user.login ], @json['mass_assignment_selected']['team_member']
    assert_equal [ @user.login ], @json['mass_assignment_selected']['scrum_master']
    
  end

  def test_destroying_empty_project
    proj = DomainChecks.disable {projects(:destroyable)}
    delete :destroy, :id => proj
    DomainChecks.disable do
      assert_response 200
      assert_match(/#{proj.name}.*(deleted|removed)/, flash[:notice])
      assert !Project.exists?(proj)
    end
  end

  def test_destroying_poject_with_items
    proj = DomainChecks.disable {projects(:bananorama)}
    delete :destroy, :id => proj
    assert_response 200
    assert !Project.exists?(proj)
    assert !flash[:notice].empty?
    assert_match /successfully deleted/, flash[:notice]
    
  end

  def test_destroying_with_bad_project_id_raises_404
    proj = DomainChecks.disable { projects(:simple_project) }
    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, :id => proj
    end
  end

  def test_reset
    post :reset_settings_to_defaults, :id => @project
    
    DomainChecks.disable do
      assert_response 200
      @project = @project.reload
      assert_equal @project.send('backlog_unit'), "SP"
    end
  end

  def test_reset_bad_project_raises_404
    project = DomainChecks.disable { projects(:simple_project) }
    DomainChecks.disable { project.update_attribute :backlog_unit, 'HP' }

    assert_raise ActiveRecord::RecordNotFound do
      post :reset_settings_to_defaults, :id => project
    end
    DomainChecks.disable do
      assert_equal 'HP', project.reload.backlog_unit
    end
  end

  def test_resetting_archived_project
    DomainChecks.disable do
      @project.archived = true
      @project.save!
    end
    post :reset_settings_to_defaults, :id => @project
    DomainChecks.disable do
      assert_response 409
      envelope = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil envelope['_error']
      assert_equal 'project_error', envelope['_error']['type']
    end
  end
  
  def test_deleting_project_with_sprint_and_all_that_stuff
    assert @user.admin?
    proj = nil
    DomainChecks.disable do 
      proj = projects(:bananorama)
      assert !proj.sprints.blank?
      proj.archived = true
      assert proj.save
    end
    delete :destroy, :id => proj
    assert_response 200

    DomainChecks.disable do
      assert !flash[:notice].empty?
      assert !Project.exists?(proj)
    end
  end
  
  def test_limit_project
    plan = plans(:simple_plan)
    Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
    @domain.save!
    @domain.update_attribute(:plan_id, plan.id)

    @user = @domain.users.first
    @request.session[:user_id] = @user
    User.current = @user
    @request.host = @domain.name + '.' + AppConfig.banana_domain
    xhr :post, :create, :project => {:name => "simple", :presentation_name => "simple", :description => "simple", :time_zone => 'Lima'}
                            
    assert_response 409
    assert_template 'new'
  end

  def test_project_description_text
    DomainChecks.disable do
      @project.description = 'test description'
      @project.save
    end
    get :project_description_text, :id => @project
    assert_response 200
    assert_equal @project.description.strip, @response.body.strip
  end

  def test_project_description_text_bad_domain
    project = DomainChecks.disable { projects(:simple_project) }
    assert_raise ActiveRecord::RecordNotFound do
      get :project_description_text, :id => project
    end
  end

  def test_archive_project
    assert !@project.archived

    post :archive, :id => @project, :project_archived => 1
    assert_response 200
    
    assert_match /archived/, flash[:notice]
    DomainChecks.disable { assert @project.reload.archived? }
  end

  def test_unarchive_project
    DomainChecks.disable do
      @project.archived = true
      @project.save!
    end
    post :archive, :id => @project, :project_archived => 0
    assert_response 200
    assert_match /unarchived/, flash[:notice]
    DomainChecks.disable { assert !@project.reload.archived? }
  end
  
  context "Updating project" do 
    should "should update free days" do
      assert @project.free_days.values.map { |v|  v == '0'}.all?
      xhr :post, :update, :id => @project.id, :project => { :free_days => { '0' => '1', '1' => '1' } }
      assert_response 200
      DomainChecks.disable { @project.reload }
      @project.free_days.each do |key, value|
        expected = ['0', '1'].include?(key) ? '1' : '0'
        assert_equal expected, value
      end
    end
    
    should "udpate project name and description and Timezone" do
      xhr :post, :update, :id => @project.id, :project => { :description => "some new descirption", :presentation_name => "new name", :time_zone => "Hawaii" }
      assert_response 200
      DomainChecks.disable { @project.reload }
      assert_equal "some new descirption", @project.description
      assert_equal "new name", @project.presentation_name
      assert_equal "Hawaii", @project.time_zone
    end
    
    should "not allow blank presentation name" do
      xhr :post, :update, :id => @project.id, :project => { :presentation_name => ""  }
      assert_response 409
      resp = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil resp['_error']
      assert_not_nil resp['_error']['message']
      assert_match /name can't be blank/, resp['_error']['message']
    end
    
  end

end

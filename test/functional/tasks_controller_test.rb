require File.dirname(__FILE__) + '/../test_helper'
require 'tasks_controller'


# Re-raise errors caught by the controller.
class TasksController; def rescue_action(e) raise e end; end

class TasksControllerTest < ActionController::TestCase
  fixtures :tasks, :backlog_elements, :users, :projects, :role_assignments, :roles

  def setup    
    DomainChecks.disable do
      @controller = TasksController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = User.find_by_login("aczajka")
      @user_id    = @user.id
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @user_id
      @item = backlog_elements(:first)
      @project = projects(:bananorama)
    end
    Juggernaut.stubs(:send_to_channels)
  end

  def test_new
    get :new, :item_id => @item, :project_id => @project.name

    assert_response :success
    assert_template 'new'

    DomainChecks.disable do
      assert_not_nil assigns(:task)
    end
    
    # fixme after implementing proper widget
#     assert_select 'option', :text => "aczajka" do
#       assert_select '[selected=?]', "selected"
#     end

  end

  def test_new_xhr
    xhr :get, :new, :item_id => @item, :project_id => @project.name
    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_match 'form', envelope['html']    
  end
  
  def test_create_xhr
    num_tasks = Task.count
    task =  {
      :summary => "sum", 
      :estimate => "1", 
      :item_id => @item.id,
    }
    xhr :post, :create, :project_id => @project.name, :task => task
    assert_response 200

    # should work for non admin as well
    DomainChecks.disable do
      @user.type = nil
      @user.save!
    end
    xhr :post, :create, :project_id => @project.name, :task => task
    assert_response 200
    assert_equal num_tasks + 2, Task.count
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    assert_not_nil envelope['html']['new']
    assert_match 'task', envelope['html']['new']
    assert_not_nil envelope['item_done']
    assert_nil envelope['_burnchart']  # this tasks is not in a sprint
  end
  
  def test_create_in_sprint
    DomainChecks.disable do
      @item_in_sprint = backlog_elements(:item_with_nil_estimate_on_sprint)
      @sprint = @item_in_sprint.sprint
      assert @sprint.ended?
      @user.type = nil
      @user.save!
    end
    task =  {
      :summary => "sum", 
      :estimate => "1", 
      :item_id => @item_in_sprint.id,
    }
    xhr :post, :create, :project_id => @project.name, :task => task
    assert_response 403

    DomainChecks.disable do
      @user.type = "Admin"
      @user.save!
    end
    xhr :post, :create, :project_id => @project.name, :task => task
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    assert_not_nil envelope['html']['new']
    assert_match 'task', envelope['html']['new']
    assert_not_nil envelope['item_done']
    assert_not_nil envelope['_burnchart']  
  end

  def test_destroy
    task = DomainChecks.disable {tasks(:task_for_user)}

    # only admin will be able to destroy as related sprint is finished
    DomainChecks.disable do
      @user.type = nil
      @user.save!
      @sprint = task.item.sprint
      assert_not_nil(@sprint)
      assert @sprint.ended?
    end
    post :destroy, :id => task.id, :project_id => @project.name
    assert_response 403

    DomainChecks.disable do
      @user.type = "Admin"
      @user.save!
    end
    post :destroy, :id => task.id, :project_id => @project.name
    assert_response :success
    response = ActiveSupport::JSON.decode(@response.body)
    assert(response['_flashes']['notice'].include?("Task '#{task.summary}' deleted."))
    assert_raise(ActiveRecord::RecordNotFound) do
      Task.find(task.id)
    end
    assert_equal("Task '#{task.summary}' deleted.", @response.flash[:notice])
    
    DomainChecks.disable do
      @project.archived = true
      @project.save
    end
    
    task = DomainChecks.disable {tasks(:third)}
    post :destroy, :id => task.id, :project_id => @project.name
    
    DomainChecks.disable do
      assert_nothing_raised(ActiveRecord::RecordNotFound) do
        Task.find(task.id)
      end
    end
  end

  def test_update_field
    estimate_task = 100
    task = DomainChecks.disable {Task.find(:first)}
    assert_not_nil(task)
    post :task_estimate, :id => task.id, :value => estimate_task, :project_id => @project.name
    
    DomainChecks.disable do
      assert_response :success
      task = task.reload
      assert_equal estimate_task, task.estimate
      envelope = ActiveSupport::JSON.decode @response.body
      assert_equal estimate_task, envelope['value']
      # We obtain these keys in envelope to know wether item or task is finished
      %W{item_done task_done}.each { |key| assert_not_nil envelope[key] }
    end
  end
  
  def test_wont_update_finished_sprint_estimate
    estimate_task = 100
    DomainChecks.disable do
      @task = tasks(:task_for_user)
      @user.type = nil
      @user.save!
      @sprint = @task.item.sprint
    end

    assert_not_nil(@task)
    assert @sprint.ended?
    post :task_estimate, :id => @task.id, :value => estimate_task, :project_id => @project.name
    assert_response 403
  end

  def test_bad_task_estimate
    task = DomainChecks.disable{Task.find(:first)}
    estimate = task.estimate
    value = ["ala ma kota", 10.02, -10, 1000]
    value.each do |v|
      post :task_estimate, :id => task.id, :value => v, :project_id => @project.name
      DomainChecks.disable do
        task = task.reload
        assert_response 409
        assert_equal estimate, task.estimate
        envelope = ActiveSupport::JSON.decode @response.body
        assert_not_nil envelope['_flashes']
        assert_not_nil envelope['_flashes']['error']
      end
    end
  end

  def test_product_owner_rights
    # User with Product Owner role
    @request.session[:user_id] = DomainChecks.disable{users(:banana_owner).id}
    task = DomainChecks.disable{tasks(:simple)}

    # Shouldn't be able to modify tasks
    xhr_get = [:new, :assign, :task_estimate, :task_summary]
    xhr_post = [:create, :destroy]

    xhr_get.each do |action|
      xhr :get, action, :id => task.id, :project_id => @project.name
      assert_response 403
    end
    xhr_post.each do |action|
      xhr :post, action, :id => task.id, :project_id => @project.name
      assert_response 403
    end
  end
  
  context "POST on assign" do
    setup do
      Domain.current = domains(:code_sprinters)
      @task = tasks(:simple)
      @user1 = users(:banana_team)
      @user2 = users(:banana_teamer)
    end
  
    should "assign single user" do
      
      post :assign, :id => @task.id, :value => @user1.login, :project_id => @project.name
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      DomainChecks.disable do
        @task.reload 
        assert_equal 1, @task.users.length
        assert @task.users.include? @user1
        assert_match @user1.login, json['login']
      end
    end
    
    should "not assign user from different project" do 
      user = users(:user_two)
      post :assign, :id => @task.id, :project_id => @project.name, :value => user.login
      assert_response 200
      DomainChecks.disable { @task.reload }
      assert @task.users.blank?
    end

    should "not assign user to finished sprint if user is not an admin" do
      @task = tasks(:task_for_user)
      @item = @task.item
      @item.project = @project
      @item.save!
      @user.type = nil
      @user.save!

      assert @task.item.sprint.ended?
      post :assign, :id => @task.id, :value => @user1.login, :project_id => @project.name
      assert_response 403

      DomainChecks.disable do
        @project.can_edit_finished_sprints = true
        @project.save!
      end
      assert @task.item.sprint.ended?
      post :assign, :id => @task.id, :value => @user1.login, :project_id => @project.name
      assert_response 200
    end
    
    should "deassing users with empty list" do
      @task.assign_users([@user1, @user2])
      assert !@task.users.blank?
      post :assign, :id => @task.id, :value => "", :project_id => @project.name
      assert_response 200
      DomainChecks.disable { @task.reload }
      assert @task.users.blank?
    end
    
    should "not assign user to archived project" do
      @project.archived = true
      assert @project.save
      assert @project.archived?
      
      post :assign, :id => @task.id, :value => @user1.login, :project_id => @project.name
      assert_response 403
      DomainChecks.disable { @task.reload }
      assert @task.users.blank?
    end
    
    should "assign multiple users" do
      post :assign, :id => @task.id, :value => "#{@user1.login},#{@user2.login}", :project_id => @project.name
      assert_response 200
      DomainChecks.disable do 
        @task.reload 
        assert_equal 2, @task.users.length
        assert @task.users.include? @user1
        assert @task.users.include? @user2
      end
    end
    
    
  end
  
  
  
  def test_update_estimate_on_archived_project
    task = DomainChecks.disable {tasks(:simple)}
    estimate_task = task.estimate + 1
    DomainChecks.disable  do
      p = task.item.project
      p.archived = true
      p.save!
    end
    
    post :task_estimate, :id => task.id, :value => estimate_task, :project_id => @project.name
    
    DomainChecks.disable do
      assert_response 403
      task = task.reload
      assert_not_equal estimate_task, task.estimate
    end
  end

  def test_sort_item
    item = DomainChecks.disable { backlog_elements(:item_belonging_to_user) }
    task = DomainChecks.disable { item.tasks[0] }
    xhr :post, :sort, :project_id => @project.name, :item => item.id, :id => task.id, :position => 1
    assert_response 200
  end

  def test_cant_sort_finished_sprint
    DomainChecks.disable do
      @item = backlog_elements(:item_belonging_to_user)
      @task = @item.tasks[0]
      @sprint = @item.sprint
      assert(@sprint.ended?)
      @user.type = nil
      @user.save!
    end
    xhr :post, :sort, :project_id => @project.name, :item => @item.id, :id => @task.id, :position => 1
    assert_response 403
  end

  def test_sort_item_bad_item
    item = DomainChecks.disable { backlog_elements(:item_belonging_to_user) }
    task = DomainChecks.disable { tasks(:simple) }
    xhr :post, :sort, :project_id => @project.name, :backlog_item => item.id, :id => task.id, :position => 1
    assert_response 404
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class ItemSweeperTest < ActionController::IntegrationTest 
  fixtures :all
  
  def teardown
    ActionController::Base.perform_caching = false
  end

  def setup
    ActionController::Base.perform_caching = true

    DomainChecks.disable do
      @user = users(:user_one)
      @project = projects(:bananorama)
      @last_sprint = @project.last_sprint
      @item = backlog_elements(:item_with_task)
      @task = tasks(:simple)
      @tag = tags(:banana)
    end
    
    get login_path, { :_domain => @user.domain.name }
    post session_path, { :login => @user.login, :password => 'alamakota', :_domain => @user.domain.name }
    assert_response :redirect
    follow_redirect!
    assert_template "sprints/show"
   end
  
  def test_admin_updates_project_units
    [
      [ admin_project_path(@project.id), :put, { :project => { :backlog_unit => "LOL" } } ],
      [ admin_project_path(@project.id), :put, { :project => { :task_unit => "LOL" } } ]
    ].each do |data|
      check_expiration_for_action(data)
    end
  end 


  def test_backlog_actions
    [
      [ backlog_item_description_project_item_path(@project.name, @item.id), :post, { :value => "new description" } ],
      [ project_item_backlog_item_tag_path(@project.name, @item.id, @tag), :delete ],
      [ project_item_backlog_item_tags_path(@project.name, @item.id), :post, { :tag => @tag.name } ],
      [ backlog_item_estimate_project_item_path(@project.name, @item.id), :post,  { :value => '1' } ],
      [ backlog_item_user_story_project_item_path(@project.name, @item.id), :post,  {:value => "new stroy" } ],
      [ project_item_path(@project.name, @item.id), :delete, {} ]
    ].each do |data|
      check_expiration_for_action(data)
    end
  end
  
  def test_tag_actions
    [
      [ project_tag_path(@project.name, @tag.id), :put, {:tag => {:name => "whatever"}}],
      [ project_tag_path(@project.name, @tag.id), :delete ]
    ].each do |data|
      check_expiration_for_action(data)
    end
  end
  
  def test_tasks_actions
  [
    [ sort_project_task_path(@project.name, @task.id), :post, { :item => @item.id, :position => 0 } ],
    [ project_tasks_path(@project.name), :post, { :task => Factory.attributes_for(:task, :item_id => @item.id) } ],
    [ assign_project_task_path(@project.name, @task.id), :post, { :value => @user.login } ],
    [ task_estimate_project_task_path(@project.name, @task.id), :post, { :value => 50 } ],
    [ task_summary_project_task_path(@project.name, @task.id), :post, { :value => "new summary" } ],
    [ project_task_path(@project.name, @task.id), :delete, {}]
  ].each do |data|
      check_expiration_for_action(data)
    end
  end
  
  def test_comments_actions
    data = [ project_item_comments_path(@project.name, @item.id), :post, { :comment => Factory.attributes_for(:comment), :item_id => @item.id } ]
    check_expiration_for_action(data)
  end
  
  protected

  def check_expiration_for_action(data)
    assert_expire_fragments(:controller => "/items", :action => "show", :id => @item.id, :project_id => @project.name, :action_suffix => :old) do
      assert_expire_fragments(:controller => "/items", :action => "show", :id => @item.id, :project_id => @project.name, :action_suffix => :new) do
        xhr data[1], data[0], data[2]
      end
    end
  end

end

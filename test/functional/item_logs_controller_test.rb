require File.dirname(__FILE__) + '/../test_helper'

class ItemLogsControllerTest < ActionController::TestCase
  fixtures :roles, :domains
    
  context "Some item with history" do
    setup do
      Domain.current = @domain = domains(:code_sprinters)
      Project.current = @project = Factory.create(:project)
      @users = [1, 2].map do
        user = Factory.create :user
        @project.role_assignments.create(:user => user, :role => roles(:team_member))
        user
      end
      User.current = @users.first
      
      @request.session[:user_id] = User.current.id
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @item = Factory.create :item, :project => @project
      4.times do
        task = Factory.create :task, :item => @item, :estimate => rand(30)
        task.assign_users([ @users.rand ] )
        2.times do
          task.increment!(:estimate)
        end
      end
      @item.update_attribute(:user_story, Factory.next(:item_story))
    end
    
    context "Simple GET without task udpates to /show" do
      setup do 
        get :index, :item_id => @item.id, :project_id => @project.name
      end
      
      should "pass" do
        assert_response :success
        resp = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil resp['html']
        assert !(resp['html'] =~ /changed estimated of the task/)
        
        assert_not_nil resp['logs_remaining']
      end
    end
    
    context "GET with task updates to /show" do
      setup do
        get :index, :item_id => @item.id, :project_id => @project.name, :estimate_updates => '1', :limit => 10
      end
      
      should 'pass' do
        assert_response :success
        resp = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil resp['html']
        assert_match /changed estimated of the task/, resp['html']
        
        assert_not_nil resp['logs_remaining']
      end
      
      context 'GET more after that' do
        setup do
          get :index, :item_id => @item.id, :project_id => @project.name, :estimate_updates => '1', :limit => 10, :skip_count => 10
        end
        
        should 'return 8 elements' do
          assert_response :success
          resp = ActiveSupport::JSON.decode(@response.body)
          assert_not_nil resp['html']
          assert_equal 8, resp['html'].scan(/class="item-log"/).length
          
          assert_not_nil resp['logs_remaining']
          assert_equal 0, resp['logs_remaining'].to_i
        end
      end
    end
    
    context "GET with filtering out by user by user who didn't do a thing" do
      setup do
        get :index, :item_id => @item.id, :project_id => @project.name, :estimate_updates => '1', :user_filter => @users.last.id
      end
      
      should 'return empty set' do
        assert_response :success
        resp = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil resp['html']
        assert !(/log/ =~ resp['html'])
      end
    end
    
    context "log created after displaying page" do
      setup do
        @timestamp = @item.logs.last.created_at
        sleep 1
        @item.update_attribute(:user_story, "new awesome user story")
      end
      
      should "not return this story if fetching with older_than param" do
        get :index, :item_id => @item.id, :project_id => @project.name, :estimate_updates => '1', :older_than => @timestamp
        assert_response :success
        resp = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil resp['html']
        assert !(/new awesome user story/ =~ resp['html'])
      end
      
      should "not return this story if fetching without older_than param" do
        get :index, :item_id => @item.id, :project_id => @project.name, :estimate_updates => '1'
        assert_response :success
        resp = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil resp['html']
        assert_match /new awesome user story/, resp['html']
      end
    end
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class TimelineControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :users, :projects, :domains, :themes

  def setup
    DomainChecks.disable do
      @controller = TimelineController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @domain = domains(:code_sprinters)
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @project = projects(:bananorama)
      Domain.current = @domain
      user = users(:user_one)
      User.current = user
      user.theme = themes(:blue)
      user.save!
      @request.session[:user_id] = user.id
    end
  end

  context "GET on project timeline with bad plan" do
    should "return 404 response" do
      get :show, :project_id => @project.name
      assert_response 404
    end
  end

  context "GET on project timeline" do
    setup do
      @domain.plan = Factory.create(:plan, :timeline_view => true, :users_limit => 100,
        :projects_limit => 100)
      @domain.save!
    end

    should "return successful response" do
      get :show, :project_id => @project.name
      assert_response :success
      past = assigns(:past_sprints)
      ongoing = assigns(:ongoing_sprints)
      active = assigns(:sprint_active)
      assert_not_nil(past)
      assert_not_nil(ongoing)
      assert_not_nil(active)

      assert past.size > 0
      assert_equal(0, ongoing.size)

      past.each do |sprint|
        assert sprint.to_date < Date.today
      end
    end

    context "with current sprints only" do
      setup do
        @project = Factory.create(:project)
        @current1 = Factory(:sprint, :from_date => 10.day.ago.to_date, :to_date => Date.today + 5.days, :project => @project, :name => "current 1")
        @current2 = Factory(:sprint, :from_date => Date.today, :to_date => Date.today + 1.days, :project => @project, :name => "current 2")
        @current3 = Factory(:sprint, :from_date => 5.day.ago.to_date, :to_date => Date.today, :project => @project, :name => "current 3")
        get :show, :project_id => @project.name
      end

      should "return success" do
        assert_response :success
        assert_equal(3, @project.sprints.size)
        past = assigns(:past_sprints)
        ongoing = assigns(:ongoing_sprints)
        assert_equal 0, past.size
        assert_equal 3, ongoing.size
      end
    end

    context "with future sprint only" do
      setup do
        @project = Factory.create(:project)
        @future = Factory(:sprint, :from_date => Date.today + 1.days, :to_date => Date.today + 14.days, :project => @project, :name => "future")
        get :show, :project_id => @project.name
      end

      should "return success" do
        assert_response :success
        assert_equal(1, @project.sprints.size)
        past = assigns(:past_sprints)
        ongoing = assigns(:ongoing_sprints)
        assert_equal 0, past.size
        assert_equal 0, ongoing.size
      end
    end

    context "with current and future sprints" do
      setup do
        @project = Factory.create(:project)
        @current1 = Factory(:sprint, :from_date => 10.day.ago.to_date, :to_date => Date.today + 5.days, :project => @project, :name => "current 1")
        @current2 = Factory(:sprint, :from_date => Date.today, :to_date => Date.today + 1.days, :project => @project, :name => "current 2")
        @current3 = Factory(:sprint, :from_date => 5.day.ago.to_date, :to_date => Date.today, :project => @project, :name => "current 3")
        @future = Factory(:sprint, :from_date => Date.today + 1.days, :to_date => Date.today + 14.days, :project => @project, :name => "future")
        get :show, :project_id => @project.name
      end

      should "return success" do
        assert_response :success
        assert_equal(4, @project.sprints.size)
        past = assigns(:past_sprints)
        ongoing = assigns(:ongoing_sprints)
        assert_equal 0, past.size
        assert_equal 3, ongoing.size
      end
    end

    context "without any sprints" do
      setup do
        @project = Factory.create(:project)
        get :show, :project_id => @project.name
      end

      should "return success" do
        assert_response :success
        assert_equal(0, @project.sprints.size)
        past = assigns(:past_sprints)
        ongoing = assigns(:ongoing_sprints)
        assert_equal 0, past.size
        assert_equal 0, ongoing.size
      end
    end

  end
end

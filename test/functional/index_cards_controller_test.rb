require File.dirname(__FILE__) + '/../test_helper'
require 'index_cards_controller'

# Re-raise errors caught by the controller.
class IndexCardsController; def rescue_action(e) raise e end; end

class IndexCardsControllerTest < ActionController::TestCase
  def setup
    @controller = IndexCardsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  context "IndexCardController" do
    setup do
      DomainChecks.disable do
        @plan = Factory.create(:free_plan, :items_limit => nil)
        @domain = Domain.default
        @project = Factory.create(:project, :domain => @domain)
        @sprint = @project.sprints.new(:domain => @domain, :name => "lalala", :from_date => Date.today, :to_date => Date.today + 14.days)
        Sprint.without_logging do
          @sprint.save
        end
        @request.host = @domain.name + "." + AppConfig.banana_domain
        @user = Factory.create(:admin, :domain => @domain)
        @request.session[:user_id] = @user.id

        User.current = @user
        Domain.current = @domain

        @items = []
        1.upto(8) do |i|
          item = Factory.create(:item_fake, :project_id => @project.id, :domain => @domain)
          Factory.create(:task_fake, :item_id => item.id)
          @items << item
        end
      end
    end

    context "on non-xhr request to index" do
      setup do
        post :index, :project_id => @project.name
      end
      should_respond_with :redirect
    end

    context "on get to index" do
      setup do
        xhr :get, :index, :project_id => @project.name
      end

      should_respond_with :success
      should_render_template :index
    end

    context "on get to index with sprint context" do
      setup do
        xhr :get, :index, :project_id => @project.name, :context => 'sprint', :sprint_id => @sprint.id
      end
      should_respond_with :success
      should_assign_to :context
    end

    context "on get to pdf with empty project" do
      setup do
        @project.items.destroy_all
        @request.env["HTTP_REFERER"] = "http://www.bananascrum.com"
        xhr :get, :pdf, :project_id => @project.name, :context => 'backlog', :sprint_id => @sprint.id
      end
      should_respond_with :redirect
    end

    context "on get to pdf with items context" do
      setup do
        xhr :get, :pdf, :project_id => @project.name, :contents => 'items', :sprint_id => @sprint.id
        Domain.current = @domain
      end
      should_respond_with :success
      should_assign_to :elements
      should_assign_to :generator
      should_change("the number of log entries", :by => 1) { IndexCardLog.count }
    end

    context "on get to pdf with sprint context" do
      setup do
        xhr :get, :pdf, :project_id => @project.name, :contents => 'all', :sprint_id => @sprint.id
        Domain.current = @domain
      end
      should_respond_with :success
      should_assign_to :elements
      should_assign_to :sprint
      should_change("the number of log entries", :by => 1) { IndexCardLog.count }
    end
  end
end

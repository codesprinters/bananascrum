require File.dirname(__FILE__) + '/../test_helper'
require 'backlog_item_tags_controller'

# Re-raise errors caught by the controller.
class BacklogItemTagsController; def rescue_action(e) raise e end; end

class BacklogItemTagsControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :users, :projects, :tags, :domains, :sprints

  def setup
    DomainChecks.disable do
      @controller = BacklogItemTagsController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new

      @domain = Domain.find_by_name(AppConfig::default_domain)
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @item = backlog_elements(:item_with_task)
      @project = @item.project
      user = users(:user_one)
      @request.session[:user_id] = user.id
    end
    Juggernaut.stubs(:send_to_channels) # FIXME: replace this stubs with expectations diffrent for each action
  end

  def test_tagging
    tag = DomainChecks.disable { tags(:banana_two) }
    tag_cnt = @item.tags.size

    post :create, :project_id => @project.name, :item_id => @item.id, :tag => tag.name
    assert_response :success

    DomainChecks.disable do
      tag_new_cnt = @item.reload.tags.size
      assert_equal tag_cnt + 1, tag_new_cnt
    end
  end

  def test_untagging
    tag = DomainChecks.disable { tags(:banana) }
    tag_cnt = @item.tags.size

    delete :destroy, :project_id => @project.name, :item_id => @item.id, :id => tag.id
    assert_response :success

    DomainChecks.disable do
      tag_new_cnt = @item.reload.tags.size
      assert_equal tag_cnt - 1, tag_new_cnt
    end
  end

end

require File.dirname(__FILE__) + '/../test_helper'

class CommentsControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :projects, :users
  
  def setup
    DomainChecks.disable do
      @controller = CommentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user_id    = User.find_by_login("aczajka").id
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @user_id
      @item = backlog_elements(:first)
      @project = @item.project
      User.current = users(:user_one)
    end
    Juggernaut.stubs(:send_to_channels)
  end
  
  def test_create
    num_comment = Comment.count
    comm = { :text => "John Smith" }
    post :create, :comment => comm, :project_id => @project.name, :item_id => @item.id
    assert_response :success
    assert_equal num_comment + 1, Comment.count
  end
end

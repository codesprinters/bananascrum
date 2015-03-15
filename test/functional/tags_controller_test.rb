require File.dirname(__FILE__) + '/../test_helper'

class TagsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  fixtures :users, :projects, :tags, :domains

  def setup
    DomainChecks.disable do
      @controller = TagsController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new

      @domain = Domain.find_by_name(AppConfig::default_domain)
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @user_id = User.find_by_login("aczajka").id
      @request.session[:user_id] = @user_id
      @first_id = tasks(:simple).id
    end
    Juggernaut.stubs(:send_to_channels)
  end

  def test_create
    post :create, :project_id => DomainChecks.disable {projects(:second).name}, :tag => {:name => 'TTTT'}

    assert_response :success

    DomainChecks.disable do
      project = projects(:second).reload
      assert project.tags.map{|t| t.name}.include?('TTTT')
      assert_equal project.tags.find_by_name('TTTT'), assigns['tag']
    end
  end

  def test_update
    tag = DomainChecks.disable {projects(:second).tags[0]}
    
    put :update, :project_id => projects(:second).name, :id => tag.id, :tag => {:name => 'EDITED'}

    assert_response :success

    DomainChecks.disable do
      tag = tag.reload
      assert_equal 'EDITED', tag.name
      assert_equal tag, assigns['tag']
    end
  end

  def test_destroy
    tag = DomainChecks.disable {projects(:second).tags[0]}
    
    delete :destroy, :project_id => projects(:second).name, :id => tag.id

    assert_response :success

    DomainChecks.disable do
      p = projects(:second).reload
      assert ! (p.tags.map {|x| x.name}.include? tag.name)
    end
  end

end

require File.dirname(__FILE__) + '/../test_helper'
require 'impediments_controller'

# Re-raise errors caught by the controller.
class ImpedimentsController; def rescue_action(e) raise e end; end

class ImpedimentsControllerTest < ActionController::TestCase
  fixtures :users, :impediments, :projects, :domains, :impediment_logs, :impediment_actions

  def setup
    DomainChecks.disable do
      @controller = ImpedimentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @request.host = "cs" + "." + AppConfig.banana_domain
      @banana = projects(:bananorama)
      user = users(:user_one)
      @request.session[:user_id] = user.id
    end
    Juggernaut.stubs(:send_to_channels)
  end

  def test_adding_impediment
    user = nil
    impediment = nil

    DomainChecks.disable do
      user = users(:user_one)
      User.current = user
      impediment = Impediment.new
      impediment.description = "testtest"
      impediment.summary = "testtest"
      impediment.project = @banana
      impediment.domain = @banana.domain
      assert impediment.valid?
    end
    
    # get should be forbidden
    xhr :get, :create, 
      {:impediment=>impediment.attributes, :project_id => @banana.name}
    assert_response 400

    post :create, 
      {:impediment=>impediment.attributes, :project_id => @banana.name}
    assert_response :redirect

    assert_redirected_to project_items_path(@banana)
  end

  def test_create_xhr
    user = nil
    impediment = nil

    DomainChecks.disable do
      user = users(:user_one)
      User.current = user
      impediment = Impediment.new
      impediment.description = "testtest"
      impediment.summary = "testtest"
      impediment.project = @banana
      impediment.domain = @banana.domain
      assert impediment.valid?
    end
    xhr :post, :create, 
      {:impediment=>impediment.attributes, :project_id => @banana.name}
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
  end

  def test_adding_invalid_impediment
    user = nil
    impediment = nil
    
    DomainChecks.disable do
      user = users(:user_one)
      User.current = user
      impediment = Impediment.new
      impediment.description = "testtest"
      assert !impediment.valid?
    end
    
    post :create, {:impediment=>impediment.attributes, :project_id => @banana.name}
    assert_response :success
    assert_template 'new'
  end

  def test_create_xhr_invalid
    user = nil
    impediment = nil
    
    DomainChecks.disable do
      user = users(:user_one)
      User.current = user
      impediment = Impediment.new
      impediment.description = "testtest"
      assert !impediment.valid?
    end

    xhr :post, :create, {:impediment=>impediment.attributes, :project_id => @banana.name}
    assert_response 409
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    assert_match /Summary can't be blank/, envelope['html']
  end

  def test_new_impediment
    imp = {
      :summary => "sum",
      :description => "test_description",
    }
    
    get :new, :project_id => projects(:bananorama).name, :imp => imp
    assert_not_nil assigns(:impediment)
    assert_response :success
    assert_template 'new'
  end

  def test_new_xhr
    imp = {
      :summary => "sum",
      :description => "test_description",
    }
    
    xhr :get, :new, :project_id => projects(:bananorama).name, :imp => imp
    assert_not_nil assigns(:impediment)
    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_match 'form', envelope['html']
  end
  
  def test_new_comment
    Domain.current = domains(:code_sprinters)
    get :new_comment, :project_id => projects(:bananorama).name, :id => impediments(:open)
    assert_response :success
    assert_template 'new_comment'

    DomainChecks.disable do
      assert_not_nil assigns(:impediment)
    end
  end

  def test_new_comment_xhr
    Domain.current = domains(:code_sprinters)
    xhr :get, :new_comment, :project_id => projects(:bananorama).name, :id => impediments(:open)
    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']

    DomainChecks.disable do
      assert_not_nil assigns(:impediment)
    end
  end

  def test_changing_impediment_status_to_closed
    impediment = DomainChecks.disable {impediments(:open)}

    xhr :post, :status, 
      {:id => impediment.id , :impediment_status=>"Closed", :project_id => @banana.name}
    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']

    DomainChecks.disable do
      assert_equal(false, impediment.reload.is_open?)
    end
  end

  def test_changing_impediment_status_to_opened
    impediment = DomainChecks.disable {impediments(:closed)}

    # get should be forbidden
    xhr :get, :status, 
      {:id => impediment.id , :impediment_status=>"Opened", :project_id => @banana.name}

    assert_response 400

    xhr :post, :status, 
      {:id => impediment.id , :impediment_status=>"Opened", :project_id => @banana.name}

    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    DomainChecks.disable do
      assert impediment.reload.is_open?
    end
  end


  def test_updating_impediment_description
    impediment = DomainChecks.disable {impediments(:closed)}

    xhr :post, :impediment_description, 
      {:id => impediment.id , :value=>"totally awesome description", :project_id => @banana.name}

    DomainChecks.disable do
      assert_response :success
      assert_equal("totally awesome description", impediment.reload.description)
      # It's only edited, should be still closed.
      assert_equal false, impediment.reload.is_open?
    end
  end

  def test_updating_impediment_summary
    impediment = DomainChecks.disable {impediments(:closed)}

    # get should be forbidden
    xhr :get, :impediment_summary, 
      {:id => impediment.id , :value=>"totally awesome summary", :project_id => @banana.name}
    assert_response 405

    xhr :post, :impediment_summary, 
      {:id => impediment.id , :value=>"totally awesome summary", :project_id => @banana.name}
    DomainChecks.disable do
      assert_response :success
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal("totally awesome summary", json['value'])
      assert_equal("totally awesome summary", impediment.reload.summary)
    end
  end

  def test_adding_comment
    impediment = DomainChecks.disable {impediments(:open)}
    project = DomainChecks.disable {impediment.project}

    comments_amount =  DomainChecks.disable {impediment.comments.size}
    post :create_comment, 
      {:id=>impediment, :comment => "Tralala", :project_id => project.name}
    assert_response :redirect
    assert_redirected_to project_items_path(project)
    DomainChecks.disable do
      assert_equal(comments_amount + 1 , impediment.comments.size)
      added_comment = impediment.comments.first.comment
      assert_equal("Tralala",added_comment )
    end
  end

  def test_adding_comment_xhr
    impediment = DomainChecks.disable {impediments(:open)}
    project = DomainChecks.disable {impediment.project}

    comments_amount =  DomainChecks.disable {impediment.comments.size}
    xhr :post, :create_comment, 
      {:id=>impediment, :comment => "Tralala", :project_id => project.name}
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    DomainChecks.disable do
      assert_equal(comments_amount + 1 , impediment.comments.size)
      added_comment = impediment.comments.first.comment
      assert_equal("Tralala",added_comment )
    end
  end

  def test_description
    impediment = DomainChecks.disable { impediments(:open) }
    xhr :get, :description, :id=>impediment, :project_id => @banana.name
    assert_response :success
  end
  
  def test_destroy_impediment_bad_method
    imp = DomainChecks.disable {impediments(:open)}
    post :destroy, :id => imp, :project_id => @banana.name
    assert_response 400
    assert_nothing_raised ActiveRecord::RecordNotFound do
      DomainChecks.disable { Impediment.find imp.id }
    end
  end

  def test_destroy
    imp = DomainChecks.disable {impediments(:open)}
    delete :destroy, :id => imp, :project_id => @banana.name
    assert_response :redirect
    assert_redirected_to project_items_url(@banana)
    assert_raise ActiveRecord::RecordNotFound do
      DomainChecks.disable { Impediment.find imp.id }
    end
  end

  def test_destroy_xhr
    imp = DomainChecks.disable {impediments(:open)}
    xhr :delete, :destroy, :id => imp.id, :project_id => @banana.name
    assert_response :success
    assert_not_nil flash[:notice]
    assert_raise ActiveRecord::RecordNotFound do
      DomainChecks.disable { Impediment.find imp.id }
    end
  end
end

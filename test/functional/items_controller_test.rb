require File.dirname(__FILE__) + '/../test_helper'
require 'items_controller'

class ItemsControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :users, :projects, :tags, :domains, :sprints, :roles
  include BacklogHelper

  def setup
    DomainChecks.disable do
      @controller = ItemsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @domain = domains(:code_sprinters)
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @banana = projects(:bananorama).name
      @user = users(:user_one)
      @request.session[:user_id] = @user.id
      @project = projects(:bananorama)

      Domain.current = @domain
      User.current = @user
    end
    Juggernaut.stubs(:send_to_channels) # FIXME: replace this stubs with expectations diffrent for each action
  end

  def test_index
    get :index, :project_id => @banana
    assert_response :success

    assert_not_nil assigns(:items)
    assert_select "#backlog-items" do
      assert_select "li#?", /item-\d+/
    end
    assert_select "div#new-item-form"
  end

  def test_xhr_index
    xhr :get, :index, :project_id => @banana
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
  end

  def test_new
    get :new, :project_id => @banana

    assert_response :success
    assert_template 'new'

    assert_select "div.redcloth-legend", /Textile markup/

    assert_not_nil assigns(:item)
  end

  def test_new_xhr
    xhr :get, :new, :project_id => @banana
    assert_response :success
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    assert_not_nil envelope['html']['new']
    assert_match 'form', envelope['html']['new']
  end

  def test_copy_item
    sprint = item = original_item = nil
    DomainChecks.disable do
      sprint = sprints(:sprint_in_april)
      original_item = sprint.items.first
    end
    post :copy, :id => original_item[:id], :project_id => @project.name
    assert_response 200
  end
 
  def test_create_valid
    project = item = tag = tag2 = nil
    DomainChecks.disable do
      project = projects(:bananorama)
      item =  { :user_story => "New item", :estimate => 1, :project => project }
      tag = tags(:banana) 
      tag2 = tags(:banana_two)
    end
    xhr :post, :create, :item => item, :project_id => project.name
    assert_response 200
    
    item =  { :user_story => "New item", :estimate => 1, :project => project }
    assert_nothing_raised do
      xhr :post, :create,
        :item => item,
        :tags => { '0' => tag.id, '6' => tag2.id },
        :new_tags => {"new_tag_nowy" => "nowy", "new_tag_nowszy" => "nowszy"},
        :project_id => project.name
      assert_response 200
      
      DomainChecks.disable do
        item = assigns(:item)
        item.reload
        assert_equal 4, item.tags.size
        assert item.tags.include?(tag)
        assert item.tags.include?(tag2)
        assert_not_nil project.tags.find_by_name("nowy")
        assert_not_nil project.tags.find_by_name("nowszy")
      end
    end
  end
  
  def test_create_at_backlog_end
    project = item = tag = nil
    DomainChecks.disable do
      project = projects(:bananorama)
      item =  { :user_story => "New item", :estimate => 1, :project => project}
      tag = tags(:banana)
    end
    xhr :post, :create, :item => item, :project_id => project.name, :'backlog-end' => '1'
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
    position = envelope['position']
    assert_not_nil position
    
    item_count = DomainChecks.disable { project.items.not_assigned.count }
    assert_equal position, item_count - 1
  end

  def test_create_xhr
    project = item = tag = nil
    DomainChecks.disable do
      project = projects(:bananorama)
      item =  { :user_story => "New item", :estimate => 1, :project => project }
      tag = tags(:banana)
    end
    xhr :post, :create, :item => item, :project_id => project.name
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']

    item =  { :user_story => "New item", :estimate => 1, :project => project }
    assert_nothing_raised do
      xhr :post, :create, :item => item, :tags => { '7' => tag.id }, :project_id => project.name
      assert_response 200
      
      DomainChecks.disable do
        item = assigns(:item)
        item.reload
        assert_equal 1, item.tags.size 
        assert item.tags.include?(tag)
      end
    end
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
  end

  def test_create_xhr_invalid
    project = item = nil
    DomainChecks.disable do
      project = projects(:bananorama)
      item =  { :user_story => "", :estimate => 1, :project => project }
    end
    xhr :post, :create, :item => item, :project_id => project.name
    assert_response 409
    envelope = ActiveSupport::JSON.decode @response.body
    assert_not_nil envelope['html']
  end

  def test_destroy
    
    item = DomainChecks.disable do backlog_elements(:item_assigned) end

    post :destroy, :id => item.id, :project_id => @banana
    assert_response :success

    json = ActiveSupport::JSON.decode @response.body
    assert json.has_key? '_burnchart'
    assert json.has_key? '_removed_markers'

    DomainChecks.disable do
      assert_raise(ActiveRecord::RecordNotFound) do
        Item.find(item.id)
      end
      assert_equal("Backlog item '#{item.user_story}' deleted.", @response.flash[:notice])
    end
  end

  def test_destroy_is_idempotent
    item = DomainChecks.disable do
      item = backlog_elements(:item_assigned)
      item.destroy
    end

    post :destroy, :id => item.id, :project_id => @banana
    assert_response :success

    json = ActiveSupport::JSON.decode @response.body
    assert !json.has_key?('_burnchart')
    assert json.has_key? '_removed_markers'
    assert_equal("Backlog item deleted.", @response.flash[:notice])
  end

  def test_set_backlog_item_estimate
    item = DomainChecks.disable {backlog_elements(:first)}
    @project.estimate_choices.each do |val|
      next if val == Item::INFINITY_ESTIMATE_REPRESENTATIVE
      post :backlog_item_estimate, :value => val, :id => item.id, :project_id => @banana
      DomainChecks.disable do 
        item.reload
      end
      json = ActiveSupport::JSON.decode(@response.body)
      assert_equal item.estimate, val
      assert_not_nil json['estimate']      
      assert_equal Item.readable_estimate(val).to_s, json['estimate'].to_s
    end
  end

  def test_long_or_multiline_helper
    multiline_string = "As God I want to have helper for killing people from time to time \n\n\n\naaaaa!"
    singleline_string = "lala im a single line lalalalalalalala"
    long_as_hell = "lala im a single line lalalalalalalalalala im a single line lalalalalalalalalala im a single line lalalalalalalalalala im a single line lalalalalalalalalala im a single line lalalalalalalalalala im a single line lalalalalalalala"
    two_lines = "As God I want to have helper for killing people from \n time to time "
    assert_equal(false, long_or_multiline?(singleline_string))
    assert_equal(false, long_or_multiline?(two_lines))
    assert(long_or_multiline?(multiline_string))
    assert(long_or_multiline?(long_as_hell))

    DomainChecks.disable do
      Item.find(:all).each do |item|
        assert_nothing_raised(Exception) { long_or_multiline?(item.description) }
      end

      assert_nothing_raised(Exception) { long_or_multiline?(nil) }
      assert_nothing_raised(Exception) { long_or_multiline?(33) }
    end
  end

  def test_product_owner_rights
    # User with Product Owner role
    @request.session[:user_id] = DomainChecks.disable {users(:banana_owner).id}

    # Can edit item
    item = DomainChecks.disable do
      backlog_elements(:first)
    end
    
    xhr :post, :backlog_item_estimate, :id => item.id, :value => 1, :project_id => @banana
    DomainChecks.disable do
      assert_response :success
      item.reload
      assert_equal 1, item.estimate
    end

    # Or access harmless actions
    xhr :get, :item_description_text, :id => item, :project_id => @banana
    assert_response :success
    xhr :get, :new, :project_id => @banana
    assert_response :success

    # But not when it is on a sprint
    DomainChecks.disable do
      item = backlog_elements(:item_assigned)
    end
    old_estimate = item.estimate
    xhr :post, :backlog_item_estimate, :id => item, :value => 2, :project_id => @banana

    assert_response 403
    DomainChecks.disable do
      item.reload
      assert_equal old_estimate, item.estimate
    end
  end
  
  def test_number_items
    get :index, :project_id => @banana
    
    DomainChecks.disable do
      backlog = projects(:bananorama).items.find(
        :all, :conditions => { :sprint_id => nil },
        :order => 'backlog_elements.position ASC, tasks.position ASC, tags.name ASC',
        :include => [:tasks, :tags]).size
      assert_equal backlog, assigns(:items).size
    end
  end
  
  def test_set_backlog_item_description
    item = DomainChecks.disable {backlog_elements(:first)}
    xhr :post, :backlog_item_description, :id => item, :value => 'outstanding description', :project_id => @banana
    assert_response :success
    json = ActiveSupport::JSON.decode(@response.body)
    assert_match('outstanding description', json['html'])
  end

  def test_cant_update_backlog_item_description_for_finished_sprint
    item = DomainChecks.disable {backlog_elements(:item_with_nil_estimate_on_sprint)}
    project = DomainChecks.disable {item.project}
    assert item.is_assigned
    DomainChecks.disable do
      project.add_user_with_role(@user, roles(:team_member))
      project.reload
      assert !project.get_user_roles(@user).blank?
      assert item.sprint.ended?
      @user.type = nil
      @user.save!
      assert !project.can_edit_finished_sprints
    end
    
    xhr :post, :backlog_item_description, :id => item, :value => 'outstanding description', :project_id => project.name
    assert_response 403
  end
  
  def test_set_backlog_item_description_for_not_mine_project
    user =DomainChecks.disable {users(:user_two)} 
    @request.session[:user_id] = user.id
    
    item = DomainChecks.disable {backlog_elements(:first)}
    xhr :post, :backlog_item_description, :id => item, :value => 'outstanding description', :project_id => @banana
    assert_response 404
    envelope = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil envelope['_error']
    assert_equal 'set_current_project', envelope['_error']['type']
  end

  
  # TESTS FOR HANDLING BLOCKED ACTIONS DUE TO ARCHIVED PROJECT BELOW
  def test_set_backlog_item_description_in_archived_project
    project = DomainChecks.disable{projects(:bananorama)}
    project.archived = true
    assert DomainChecks.disable {project.save}
    
    item = DomainChecks.disable {backlog_elements(:first)}
    old_description = item.description
    
    xhr :post, :backlog_item_description, :id => item, :value => 'outstanding description', :project_id => @banana
    assert_response 403
    assert_equal old_description, DomainChecks.disable {backlog_elements(:first).description}
  end
  
  def test_set_backlog_item_estimate_in_archived_project
    project = DomainChecks.disable{projects(:bananorama)}
    project.archived = true
    assert DomainChecks.disable {project.save}
    
    item = DomainChecks.disable {backlog_elements(:item_with_nil_estimate)}
    
    old_estimate = item.estimate
    
    xhr :post, :backlog_item_estimate, :id => item, :value => 2, :project_id => @banana
    assert_response 403
    assert_equal old_estimate, DomainChecks.disable {backlog_elements(:item_with_nil_estimate).estimate}
  end


  def test_create_backlog_item_but_project_is_archived
    project = item = nil
    count = nil
    DomainChecks.disable do
      project = projects(:bananorama)
      item =  { :user_story => "New item", :estimate => 1, :project_id => project }
      count = project.items.count
    end
    project.archived = true
    DomainChecks.disable{project.save!}
    
    post :create, :item => item, :project_id => project.name
    assert_response 403
    
    assert_equal count , DomainChecks.disable{project.reload.items.count}
  end
  
  def test_destroy_on_archived_project
    item = count = project = nil
    DomainChecks.disable do 
      item = backlog_elements(:first)
      project = item.project
      count = project.items.count
    end
    project.archived = true
    DomainChecks.disable{project.save!}
    
    post :destroy, :id => item.id, :project_id => @banana
    assert_response 403
    assert_equal count , DomainChecks.disable{project.reload.items.count}
  end

  def test_setting_backlog_user_story
    item = project = nil
    DomainChecks.disable do 
      item = backlog_elements(:first)
      project = item.project
    end
    xhr :post, :backlog_item_user_story, :project_id => project.name, :id => item.id, :value => "my story"
    assert_response 200
    envelope = ActiveSupport::JSON.decode(@response.body)
    DomainChecks.disable do
      assert_equal(item.id.to_s, envelope['item'].to_s)
      assert_equal("my story", envelope['value'])
      assert_equal("my story", item.reload.user_story)
    end
  end

  def test_setting_user_story_on_nonexistent_item
    item_id = project = nil
    DomainChecks.disable do 
      item = backlog_elements(:first)
      project = item.project
      item_id = item.id
      item.destroy
    end
    xhr :post, :backlog_item_user_story, :project_id => project.name, :id => item_id, :value => "my story"
    assert_response 404
    envelope = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil envelope['_error']
    assert_equal 'not_found', envelope['_error']['type']
  end

  def test_sort_backlog
    item_id = nil
    position = nil
    DomainChecks.disable do
      project = Project.find :first, :conditions => { :name => @banana }
      item_id = project.items.not_assigned[0].id
      position = 2
    end
    post :sort, :project_id => @banana, :item => item_id, :position => position
    assert_response 200
    envelope = ActiveSupport::JSON.decode @response.body
    assert envelope.has_key? '_removed_markers'
  end
  
  def test_import_csv
    separator = ','
    csv = StringIO.new([
        ["Story0", "2", "desc", '"tag1,tag2"',"s1","s2"].join(separator),
        ["Story1", "ola", "desc", '"tag1,tag2"'].join(separator),
        ["Story2", "1", "desc"].join(separator),
        ["Story3", "5"].join(separator),
        ['"User, asdf, asdfasdf"', "5", '"Usraer, awerwerwe, erwerwe, asdfasdf"'].join(separator),
    ].join("\n"))
    post :import_csv, :csv => csv, :project_id => @banana
    assert_response 200
    json = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil json['html']
    assert_not_nil json['html']['new']
    assert_not_nil json['html']['old']
    assert_not_nil json['tag_in_cloud']
    assert_not_nil json['tag_in_cloud']['new']
    assert_not_nil json['tag_in_cloud']['old']
    assert json['tag_in_cloud']['new'].match /tag1/
  end

  def test_sort_backlog_with_bad_project_returns_404
    item_id = nil
    position = nil
    DomainChecks.disable do
      project = Project.find :first, :conditions => { :name => @banana }
      item_id = backlog_elements(:item_assigned_and_liked).id
      position = 2
    end
    post :sort, :project_id => @banana, :item => item_id, :position => position
    assert_response 404
  end

  def test_bulk_add
    assert_difference "Item.count", 2 do
      assert_difference "Task.count", 2 do
        post :bulk_add, :project_id => @banana, :text => "As a user I want to be cool\n task 1\n task 2\nAnother item"
        assert_response 200
      end
    end
    json = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil json['html']
    assert_not_nil json['html']['new']
    assert_not_nil json['html']['old']
    assert_match "As a user I want to be cool", json['html']['old']
    assert_not_nil json['_flashes']['notice']
    assert_match /Created 2 backlog items/, json['_flashes']['notice']
  end
  
  def test_get_on_bulk_add
    get :bulk_add, :project_id => @banana
    assert_response 200
    json = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil json['html']
    assert_match /Bulk add backlog items/, json['html']
    assert_match /<textarea/, json['html']
  end
  
  def test_buld_add_without_text_param
    post :bulk_add, :project_id => @banana
    assert_response 200
  end

  context 'item limit' do
    setup do
      @plan = Factory.create(:plan_with_item_limit, :items_limit => 2)
      @domain = Factory.create(:domain, :plan => @plan)
    end
  end
end 

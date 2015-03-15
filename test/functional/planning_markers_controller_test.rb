require File.dirname(__FILE__) + '/../test_helper'

class PlanningMarkersControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :users, :projects, :domains
  def setup
    DomainChecks.disable do
      @controller = PlanningMarkersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @domain = domains(:code_sprinters)
      @request.host = domains(:code_sprinters).name + "." + AppConfig.banana_domain
      @banana = projects(:bananorama).name
      user = users(:user_one)
      @request.session[:user_id] = user.id
    end
  end
  
  context "Distributing markers" do
    setup do
      Domain.current = @domain
      @project = Factory.create(:project, :domain => @domain)
      @user = Factory.create(:user)
      User.current = @user
      50.times { |i| Factory.create(:item, :project => @project, :estimate => 3) }
    end

    context 'after post to distribute by 6SP' do
      setup do
        xhr :post, :distribute, :velocity => 6, :project_id => @project.name
        Domain.current = @domain
      end

      should_change("the number of planning markers", :by => 24) {PlanningMarker.count}

      should_respond_with :success
      should "have markers with proper positions" do
        @project.planning_markers.each_with_index do |pm, index|
          expected_position = (index + 1) * 3 - 1 # 2,5,8,11,...
          assert_equal expected_position, pm.position
        end
      end

      context 'then post to :destroy_all' do
        setup do
          xhr :post, :destroy_all, :project_id => @project.name
          Domain.current = @domain
        end

        should_change("the number of planning markers", :from => 24) {PlanningMarker.count}
        should_change("the number of planning markers", :to => 0) {PlanningMarker.count}
        should_respond_with :success
      end

      context 'then post to :destroy_all on archived project' do
        setup do
          @project.archived = true
          @project.save!
          xhr :post, :destroy_all, :project_id => @project.name
          Domain.current = @domain
        end

        should_not_change("the number of planning markers") {PlanningMarker.count}
        should_respond_with 403
      end
    end
    
    context "with big item on the begining" do
      setup do
        Factory.create(:item, :project => @project, :estimate => 20, :position => 0)
      end
    
      should "keep the big one in one span, rest stay the same" do
        assert_difference "PlanningMarker.count", 25 do
          xhr :post, :distribute, :velocity => 6, :project_id => @project.name
          assert_response 200
        end
        Domain.current = @domain
        @project.planning_markers.each_with_index do |pm, index|
          expected_position = (index) * 3 + 1 # 1,4,7,10,13,... 
          assert_equal expected_position, pm.position
        end
      end
    end
    
    context "with big item in the middle" do
      setup do
        Factory.create(:item, :project => @project, :estimate => 20, :position => 2)
      end
    
      should "give correct positions" do
        assert_difference "PlanningMarker.count", 25 do
          xhr :post, :distribute, :velocity => 6, :project_id => @project.name
          assert_response 200
        end
        Domain.current = @domain
        expected_positions = [ 2, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49, 52, 55, 58, 61, 64, 67, 70, 73 ,76 ]
        @project.planning_markers.each_with_index do |pm, index|
          expected_position = expected_positions.shift
          assert_equal expected_position, pm.position
        end
      end
    end
  end
  
  context "On product backlog" do
    setup do
      DomainChecks.disable do
        @project = projects(:bananorama)
      end
    end

    should "create valid planning marker" do
      xhr :post, :create, :project_id => @project.name, :position => 1
      assert_response 200
      envelope = ActiveSupport::JSON.decode @response.body
      assert_not_nil envelope['marker']
      assert_equal '1', envelope['position'].to_s
    end

    should "return conflict when trying to put marker on invalid position" do
      xhr :post, :create, :project_id => @project.name, :position => "0"
      assert_response 409
      envelope = ActiveSupport::JSON.decode @response.body
      assert_not_nil envelope['_error']
      assert_equal 'planning_marker_create', envelope['_error']['type']
    end

    context "with planning marker" do
      setup do
        DomainChecks.disable do
          @marker = PlanningMarker.new
          @marker.project = @project
          @marker.position = @project.backlog_elements.not_assigned.count / 2
          @marker.domain = @project.domain
          @marker.save!
        end
      end

      should "not save new planning marker next to existing one" do
        xhr :post, :create, :project_id => @project.name, :position => (@marker.position + 1).to_s
        assert_response 409
        envelope = ActiveSupport::JSON.decode @response.body
        assert_not_nil envelope['_error']
        assert_equal 'planning_marker_create', envelope['_error']['type']
      end

      should "not save planning marker on invalid position" do
        xhr :put, :update, :project_id => @project.name, :id => @marker.id, :position => (@marker.position + 100).to_s
        assert_response 409
        envelope = ActiveSupport::JSON.decode @response.body
        assert_not_nil envelope['_error']
        assert_equal 'planning_marker_update', envelope['_error']['type']
        assert_equal @marker.id.to_s, envelope['marker'].to_s
        assert_equal @marker.position.to_s, envelope['position'].to_s
      end
      
      should "save new planning marker in other place" do
        xhr :post, :create, :project_id => @project.name, :position => (@marker.position - 2).to_s
        assert_response 200
        envelope = ActiveSupport::JSON.decode @response.body
        assert_not_nil envelope['marker']
        assert_equal '1', envelope['position'].to_s
      end

      should "update planning marker position" do
        new_position = (@marker.position - 1).to_s
        xhr :put, :update, :project_id => @project.name, :id => @marker.id, :position => new_position
        assert_response 200
        envelope = ActiveSupport::JSON.decode @response.body
        assert_nil envelope['_error']
        assert_not_nil envelope['marker']
        assert_equal new_position, envelope['position'].to_s
      end

      should "delete planning marker" do
        marker_id = @marker.id
        xhr :delete, :destroy, :project_id => @project.name, :id => @marker.id
        assert_response 200
        envelope = ActiveSupport::JSON.decode(@response.body)
        assert_equal @marker.id.to_s, envelope['marker'].to_s
        DomainChecks.disable do
          assert_raise ActiveRecord::RecordNotFound do
            @project.backlog_elements.not_assigned.find marker_id
          end
        end
      end

      should "return 404, when attempting to delete nonexistent marker" do
        xhr :delete, :destroy, :project_id => @project.name, :id => 10000000
        assert_response 404
        envelope = ActiveSupport::JSON.decode @response.body
        assert_not_nil envelope['_error']
        assert_equal 'not_found', envelope['_error']['type']
      end
    end
  end
end

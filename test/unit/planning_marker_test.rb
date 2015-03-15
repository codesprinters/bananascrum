require File.dirname(__FILE__) + '/../test_helper'

class PlanningMarkerTest < ActiveSupport::TestCase
  fixtures :backlog_elements, :projects

  should_belong_to :project
  should_validate_presence_of :position

  should 'have named scope :locked' do
    Domain.current = domains(:code_sprinters)
    markers = Domain.current.projects[0].planning_markers.locked
    assert_match /locked_by_id IS NOT NULL/, markers.scope(:find)[:conditions]
  end

  context "Planning marker instance" do
    setup do
      @domain = Domain.current = domains(:code_sprinters)
      @user = User.current = @user_one = users(:user_one)
      
      @project = projects(:bananorama)
      @marker = PlanningMarker.new
      @marker.project = @project
    end

    should "allow positions in backlog, except first and last" do
      item_count = @project.backlog_elements.not_assigned.count
      forbidden_positions = [0, -1, item_count + 1, item_count]
      forbidden_positions.each do |position|
        @marker.position = position
        assert !@marker.valid?
        assert_not_nil @marker.errors[:position]
      end

      (item_count - 1).times do |i|
        @marker.position = i + 1
        assert @marker.valid?
      end
    end

    context "that is saved" do
      setup do
        # We have to fix order first
        @expected_position = @project.backlog_elements.not_assigned.count / 2
        @marker.position = @expected_position
        @marker.save!
      end

      should "preserve backlog order" do
        assert_equal @expected_position, @marker.position
        check_order(@project)
      end

      context "in a backlog with another planning marker" do
        setup do
          @another_marker = PlanningMarker.new
          @another_marker.project = @project
        end

        should "not be saved next to another planning marker" do
          forbidden_positions = [@marker.position, @marker.position + 1]
          forbidden_positions.each do |position|
            @another_marker.position = position
            assert !@another_marker.valid?
            assert_not_nil @another_marker.errors[:position]
          end
        end

        should "be saved on other positions" do
          allowed_positions = [@marker.position - 1, @marker.position + 2]
          allowed_positions.each do |position|
            @another_marker.position = position
            assert @another_marker.valid?
          end
        end
      end
    end
  end

  context "Project with three markers" do
    setup do
      @domain = Domain.current = domains(:code_sprinters)
      @user = User.current = @user_one = users(:user_one)
      @project = projects(:bananorama)
      item_count = @project.backlog_elements.not_assigned.count
      @markers = []
      @markers << PlanningMarker.create!(:project => @project, :position => (item_count / 3))
      @markers << PlanningMarker.create!(:project => @project, :position => (1 + item_count / 2))
      @markers << PlanningMarker.create!(:project => @project, :position => (3 + item_count / 2))
    end

    should "return sprint names" do
      sprints_to_plan_names = @project.sprints_to_plan_names
      @markers.length.times do |idx|
        assert_equal sprints_to_plan_names[idx], @markers[idx].sprint_name
      end
    end

    should "return sprint names, even if project has no sprints to plan" do
      @project.sprints_to_plan.each { |s| s.destroy }
      sprints_to_plan_names = @project.sprints_to_plan_names
      @markers.length.times do |idx|
        assert_equal sprints_to_plan_names[idx], @markers[idx].sprint_name
      end
    end

    should "return sprint's ending date, if assosiated sprint exists" do
      sprints_to_plan = @project.sprints_to_plan
      planning_markers = @project.planning_markers
      planning_markers.length.times do |idx|
        expected_to_date = sprints_to_plan[idx].nil? ? nil : sprints_to_plan[idx].to_date
        assert_equal expected_to_date, planning_markers[idx].sprint_to_date
      end
    end

    should "return estimate of preceeding items" do
      sum = 0
      @project.backlog_elements.not_assigned.each do |e|
        if e.type == 'Item'
          sum += (e.estimate.nil? or e.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE) ? 0 : e.estimate
        elsif e.type == 'PlanningMarker'
          assert_equal sum, e.effort
          sum = 0
        end
      end
    end

  end

  private
  def check_order(project)
    i = 0
    project.backlog_elements.not_assigned.each do |e|
      assert_equal i, e.reload.position
      i += 1
    end
  end
end

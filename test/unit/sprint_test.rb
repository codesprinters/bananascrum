require File.dirname(__FILE__) + '/../test_helper'

class SprintTest < ActiveSupport::TestCase
  fixtures :sprints, :backlog_elements, :tasks, :task_logs, :projects

  def setup
    super
    Domain.current = @domain = domains(:code_sprinters)
    Project.current = @project = projects(:bananorama)
    User.current = users(:user_one)
  end

  def teardown
    super
    Domain.current = nil
    User.current = nil
  end

  # Test adding a new sprint
  def test_add_sprint
    sprint = Sprint.new(:name => "test sprint",
      :from_date => Date.today + 14,
      :to_date => Date.today + 21,
      :goals => "some goals",
      :project => @project)
    
    assert_nothing_raised(Exception) { sprint.save! }
  end

  # Test adding a new sprint with a duplicate name
  def test_add_duplicate_sprint_name
    sprint = sprints(:sprint_one)
    future_date = Date.today + 3
    new_sprint = Sprint.new(:name => sprint.name,
      :from_date => Date.today,
      :to_date => future_date,
      :goals => "some goals",
      :project => @project)
    assert !new_sprint.valid?
    
    # but works for other project
    new_sprint.project = projects(:destroyable)
    
    assert new_sprint.valid?
  end

  # Test adding a new sprint without required fields
  def test_add_without_required_fields
    sprint = Sprint.new
    assert !sprint.valid?
    assert sprint.errors.invalid?(:from_date)
    assert sprint.errors.invalid?(:to_date)
    assert sprint.errors.invalid?(:name)
    assert !sprint.save
  end

  # Test two new sprints which overlaps with eachother
  def test_add_overlaping_sprints
    sprint1 = Sprint.new(:name => "test sprint",
      :from_date => Date.today + 14,
      :to_date => Date.today + 21,
      :project => @project)
    assert_nothing_raised(Exception) { sprint1.save! }
    
    sprint2 = Sprint.new(:name => "test sprint 2",
      :from_date => Date.today,
      :to_date => Date.today + 7,
      :project => @project)
    assert_nothing_raised(Exception) { sprint2.save! }

  end

  # Test date span for sprint
  def test_sprint_date_span
    current_date = Date.today
    sprint = Sprint.new(:name => "some sprint",
      :from_date => current_date,
      :to_date => current_date,
      :goals => "some goals",
      :project => @project)
    assert !sprint.valid?
    assert !sprint.save
  end

  # Test getting assigned backlog items
  def test_get_assigned_items
    sprint = sprints(:sprint_with_assigned_tasks)
    empty_sprint = sprints(:empty_sprint)
    assert_equal(4, sprint.items.to_a.length)
    assert_equal(0, empty_sprint.items.to_a.length)
  end

  def test_sprint_with_deleted_item
    sprint = Sprint.create(:name => "S", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    item = Item.create(:user_story => "buu", :estimate => 1, :sprint => sprint, :project => @project)
    task = Task.create(:summary => "not-important", :estimate => 9, :item => item)

    assert_equal(sprint, task.task_logs[0].sprint)
    assert_equal(1, sprint.task_logs.size)
    
    task.destroy

    assert_equal(2, sprint.task_logs.size)
  end

  def test_move_items_to_backlog_after_deleted_sprint
    sprint = Sprint.create!(:name => "new_sprint", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    item = Item.create!(:user_story => "new_backlog", :estimate => 1, :sprint => sprint, :project => @project)
    Task.create!(:summary => "not-important", :estimate => 9, :item => item)
    
    assert sprint.destroy
    assert !Item.exists?(item.id)
  end

  def test_number_developers_in_sprint
    sprint = Sprint.create(:name => "U", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    item = Item.create(:user_story => "developer", :estimate => 1, :sprint => sprint, :project => @project)
    jezyk = users(:banana_teamer)
    task = Task.create(:task_users_attributes => [ { :user => jezyk } ], :summary => "one-developer", :estimate => 9, :item => item)
    
    assert_equal 1, sprint.users.count
    assert_same_elements [jezyk], sprint.users
       
    blackpen = users(:banana_team)
    task.task_users.destroy_all
    task.users << blackpen

    assert_equal 1, sprint.users.count(true)
    assert_same_elements [blackpen], sprint.users(true)
    
    task = Task.create(:task_users_attributes => [ { :user => jezyk } ], :summary => "one-developer", :estimate => 9, :item => item)
  
    assert_equal 2, sprint.users.count(true)
    assert sprint.users(true).include?(blackpen)
    assert sprint.users(true).include?(jezyk) 
  end

  def test_number_developers_in_empty_sprint
    sprint = Sprint.create(:name => "U", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    
    assert_equal 0, sprint.users.count
    assert sprint.users.empty?
  end
  
  def test_unassigned_developers_in_sprint
    sprint = Sprint.create(:name => "U", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    item = Item.create(:user_story => "developer", :estimate => 1, :sprint => sprint, :project => @project)
    task = Task.create(:summary => "one-developer", :estimate => 9, :item => item)
    User.current = nil
    
    assert_equal 0, sprint.users.count
    assert sprint.users.empty?    
  end

  def test_add_sprint_that_lasts_too_long
    sprint = sprints(:sprint_one)

    assert sprint.valid?

    sprint.to_date = sprint.from_date + Sprint::MAX_LENGTH
    assert_equal Sprint::MAX_LENGTH + 1, sprint.length
    assert !sprint.valid?

    sprint.to_date = sprint.from_date + Sprint::MAX_LENGTH - 1.day
    assert_equal Sprint::MAX_LENGTH, sprint.length
    assert sprint.valid?
  end

  def test_sprint_length
    sprint = Sprint.new
    assert sprint.from_date.nil?
    assert sprint.to_date.nil?
    assert sprint.length.nil?

    sprint.from_date = Date.today
    assert sprint.length.nil?

    # Remember that to date is inclusive
    sprint.to_date = Date.today + 1.day
    assert_equal 2, sprint.length
  end

  def test_validating_sequence_numbers
    s = sprints(:sprint_one)
    some_number = 1418

    s.sequence_number = some_number
    assert s.valid?
    assert_equal(true, s.save)

    # testing already used sequnce_number id
    new_one = sprints(:sprint_one).clone
    new_one.from_date = "2077-01-24".to_date  # in case of some fixture which would
    new_one.to_date  = "2077-01-25".to_date   # take the date and make conflict
    new_one.id = some_number
    new_one.name = 'temporary_one'
    assert !new_one.save
    # some other number should have been assigned
    all_in_bananorama = Sprint.find(:all, :conditions => "project_id = #{new_one.project.id}")


    # checks if for sequence numbers uniqueness in bananorama project
    sequence_numbers = []
    all_in_bananorama.each  do |sprint|
      sequence_numbers << sprint.sequence_number unless sprint.sequence_number.nil?
    end
    assert_equal(sequence_numbers, sequence_numbers.uniq)

    # testing on update to number already taken by other sprint from the same project
    new_one.sequence_number = some_number
    assert_equal(false,new_one.valid?)
    assert_equal(false, new_one.save)

    # it should be possible that sequence numbers are the same on different projects
    second_project = projects(:second)
    # making sprint in different project that will have same sequence number
    diff_proj_sprint = Sprint.new
    diff_proj_sprint = sprints(:sprint_in_second_project).clone
    diff_proj_sprint.name = 'other'
    diff_proj_sprint.from_date = "2077-01-24".to_date
    diff_proj_sprint.to_date  = "2077-01-25".to_date
    diff_proj_sprint.sequence_number = new_one.sequence_number
    assert(diff_proj_sprint.valid?)
    assert(diff_proj_sprint.save)

    # checking on update, this is allowed as it's in different project
    diff_proj_sprint.sequence_number = s.sequence_number
    assert diff_proj_sprint.save
    assert_equal(diff_proj_sprint.sequence_number,s.sequence_number)
  end

  def test_sequence_number_starts_with_one
    project = projects(:destroyable)
    assert project.sprints.empty?

    sprint = Sprint.new(:name => "First sprint",
                        :from_date => Date.today,
                        :to_date => Date.today + 7,
                        :goals => "some goals",
                        :project => project
                       )
    assert sprint.save
    assert_equal 1, sprint.sequence_number
  end
  
  def test_estimated_effort
    project = projects(:bananorama)
    sprint = Sprint.create(:name => "Sprint",
      :from_date => Date.today,
      :to_date => Date.today + 7,
      :goals => "some goals",
      :project => project)

    expected = sprint.items_estimated_effort
    item = Item.create(:user_story => "backlog-name",
      :estimate => 3,
      :project => project,
      :sprint => sprint)

    assert_equal expected + item.estimate, sprint.reload.items_estimated_effort
    
    sprint.items.destroy_all
    assert_equal 0, sprint.reload.items_estimated_effort
    
    expected_sum = sprint.items_estimated_effort
    item = Item.create(:user_story => "backlog-name",
      :estimate => 2,
      :project => project,
      :sprint => sprint)
    assert_equal expected_sum + item.estimate, sprint.reload.items_estimated_effort
    
    expected_sum = sprint.items_estimated_effort
    item = Item.create(:user_story => "backlog-name",
      :estimate => 0.5,
      :project => project,
      :sprint => sprint)
    assert_equal expected_sum + item.estimate, sprint.reload.items_estimated_effort
  end
  
  def test_number_not_estimated_assigned_items
    sprint = Sprint.create(:name => "Sprint", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    expected = sprint.items.not_estimated.size
    
    Item.create(:user_story => "one_backlog", :estimate => 0.5, :sprint => sprint, :project => @project)
    assert_equal expected, sprint.reload.items.not_estimated.size
    
    Item.create(:user_story => "two_backlog", :estimate => 0, :sprint => sprint, :project => @project)
    assert_equal expected, sprint.reload.items.not_estimated.size
    
    Item.create(:user_story => "three_backlog", :estimate => nil, :sprint => sprint, :project => @project)
    assert_equal expected + 1, sprint.reload.items.not_estimated.size
  end
  
  def test_number_assigned_tasks
    sprint = Sprint.create(
      :name => "Sprint", 
      :from_date => Date.today, 
      :to_date => (Date.today + 1), 
      :project => @project
    )
    
    item = Item.create(
      :user_story => "one_backlog", 
      :estimate => 1, 
      :sprint => sprint, 
      :project => @project
    )
    
    two_item = Item.create(
      :user_story => "two_backlog", 
      :estimate => 2, 
      :sprint => sprint, 
      :project => @project
    )
    
    expected = sprint.tasks.size
    
    Task.create(:summary => "one_developer", :estimate => 9, :item => item)
    Task.create(:summary => "two_developer", :estimate => 12, :item => item)
    Task.create(:summary => "two_developer", :estimate => 12, :item => two_item)
    
    assert_equal expected + 3, sprint.reload.tasks.size
  end

  def test_stats_for_printing
    sprint = sprint_with_ordered_items
    stats = {}
    assert_nothing_raised do
      stats = sprint.stats_for_printing
    end
    assert_not_nil stats

    stats.each do |key, val|
      assert_not_nil stats[key]
    end

  end
  
  def test_remaining_days
    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    Date.expects(:current).returns("2008-06-19".to_date)
    assert_equal sprint.remaining_days, 5
    
    Date.expects(:current).returns("2008-06-24".to_date)
    assert_equal sprint.remaining_days, 0
    
    sprint = Sprint.new
    sprint.remaining_days
    assert_equal sprint.to_date, nil 
  end

  def test_remaining_work_days
    @project.free_days = {'6' => '1', '0' => '1'}
    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    Date.stubs(:current).returns("2008-06-19".to_date)
    assert_equal 3, sprint.remaining_work_days

    @project.free_days = {'6' => '1', '0' => '1', '1' => '1'}
    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    Date.stubs(:current).returns("2008-06-19".to_date)
    assert_equal 2, sprint.remaining_work_days

    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    Date.stubs(:current).returns("2008-06-24".to_date)
    assert_equal 0, sprint.remaining_work_days

    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    Date.stubs(:current).returns("2008-06-25".to_date)
    assert_equal 0, sprint.remaining_work_days
  end
  
  def test_length_sprint
    sprint = Sprint.create(:name => "Sprint", :from_date => "2008-06-01".to_date, :to_date => "2008-06-24".to_date, :project => @project)
    assert_equal sprint.length, 24
  end

  def test_rearrange_items_set_nil
    sprint = sprint_with_ordered_items
    item = sprint.items[0]
    item.position_in_sprint = nil
    item.save
    item.reload
    check_items_order sprint.reload
    assert_equal sprint.items.count - 1, item.position_in_sprint
  end

  def test_rearrange_items_set_as_first_item
    sprint = sprint_with_ordered_items
    item = sprint.items[-1]
    item.position_in_sprint = 0
    item.save
    item.reload
    check_items_order sprint.reload
    assert_equal 0, item.position_in_sprint
  end

  def test_rearrange_items_set_as_last
    sprint = sprint_with_ordered_items
    item = sprint.items[0]
    item.position_in_sprint = sprint.items.count - 1
    item.save
    item.reload
    check_items_order sprint.reload
    assert_equal(sprint.items.count - 1, item.position_in_sprint)
  end

  def test_rearrange_items_desired_position
    sprint = sprint_with_ordered_items
    item = sprint.items[-1]
    desired_position = (sprint.items.count / 2).to_i
    item.position_in_sprint = desired_position
    item.save!
    item.reload
    check_items_order sprint.reload
    assert_equal desired_position, item.position_in_sprint
  end

  def test_rearrange_items_too_small_position_is_treated_as_first
    sprint = sprint_with_ordered_items
    item = sprint.items[-1]
    item.position_in_sprint = -1
    item.save
    item.reload
    check_items_order sprint.reload
    assert_equal 0, item.position_in_sprint
  end

  def test_rearrange_items_too_big_position_is_treated_as_last
    sprint = sprint_with_ordered_items
    item = sprint.items[0]
    item.position_in_sprint = sprint.items.count
    item.save!
    item.reload
    check_items_order sprint.reload
    assert_equal(sprint.items.count - 1, item.position_in_sprint)
  end

  # FIXME: More test cases for this
  #        * Assign to sprint with no items
  #        * Assign to sprint with many items to desired position
  #        * Assign to sprint with no items on desired position should behave
  #          gracefully
  #        * Check wrong values (too big desired position, negative value,
  #          etc.)

  context "Assign item to sprint" do
    setup do
      @sprint = Factory(:sprint, :project => @project)
      10.times { Factory(:item, :project => @project, :sprint => @sprint) }
      @item = Factory(:item, :project => @project)
    end

    should "have correct setup environment" do
      assert_not_nil 0, @item.position
      assert_nil @item.position_in_sprint
      @sprint.items.each do |item|
        assert_nil item.position
        assert_not_nil item.position_in_sprint
      end
    end

    should "work with position given" do
      @sprint.assign_item @item, 2
      assert_equal @sprint, @item.sprint
      assert_nil @item.position
      assert_equal 2, @item.position_in_sprint
    end

    should "work without position given" do
      @sprint.assign_item @item
      assert_equal @sprint, @item.sprint
      assert_nil @item.position
      assert_equal 10, @item.position_in_sprint
    end

    should "Behave well with unassigning" do
      item = @sprint.items.first
      assert_nil item.position
      item.sprint = nil
      item.save!
      item.reload
      check_items_order(@sprint)
      assert_nil item.position_in_sprint
      assert_not_nil item.position
    end

    context "from other sprint" do
      setup do
        @other_sprint = Factory(:sprint, :project => @project)
        @item = @sprint.items.first
        5.times do |i|
          Factory(:item, :sprint => @other_sprint, :project => @project, :user_story => i.to_s)
        end
        
      end

      context "do the last position" do
        setup do
          @other_sprint.assign_item @item
        end
      
  
        should "go to last position" do
          assert_equal @other_sprint.items.count - 1, @item.position_in_sprint
        end
  
        should "have correct positions in both sprints" do
          check_items_order(@sprint)
          check_items_order(@other_sprint)
        end
      
        should "not change positions of previous items" do
          @other_sprint.items.each_with_index do |item, index|
            next if index == 5
            assert_equal index.to_s, item.user_story
          end
        end
      end

      context "to the second position" do
        setup do
          @other_sprint.assign_item @item, 1
        end
      

        should "go to second position" do
          assert_equal 1, @item.position_in_sprint
        end

        should "have correct positions in both sprints" do
          check_items_order(@sprint)
          check_items_order(@other_sprint)
        end

        should "update positions of other items" do
          @other_sprint.items.each_with_index do |item, index|
            next if index == 1
            item_at_position = index > 1 ? index - 1 : index
            assert_equal item_at_position.to_s, item.user_story
          end
        end

      end

    end
  end

  context "Try to edit sprint" do
    setup do
      @sprint = Factory(:sprint, :project => @project, :from_date => 21.days.ago.to_date, :to_date => 7.days.ago.to_date)
      10.times { Factory(:item, :project => @project, :sprint => @sprint) }
      @item = Factory(:item, :project => @project)
      @user = users(:user_one)
    end

    should "be possible for admin" do
      assert @sprint.can_be_edited_by?(@user)
    end

    should "not be possible for not admin" do
      @user = Factory(:user)
      assert !@sprint.can_be_edited_by?(@user)
    end

    should "be possible for not admin if project has can_edit_finished_sprints set to true" do
      @user = Factory(:user)
      @project.can_edit_finished_sprints = true
      @project.save!
      assert @sprint.can_be_edited_by?(@user)
    end

    should "be possible for not admin if sprint still in progress" do
      @user = Factory(:user)
      @sprint.to_date = Date.today + 1.day
      @sprint.save!
      assert !@sprint.ended?
      assert @sprint.can_be_edited_by?(@user)
    end


  end

  context "Project with few sprints" do
    setup do
      @project = Factory.create(:project)
      @past = Factory(:sprint, :from_date => 30.day.ago.to_date, :to_date => 5.day.ago.to_date, :project => @project, :name => "past")
      @current1 = Factory(:sprint, :from_date => 10.day.ago.to_date, :to_date => Date.today + 5.days, :project => @project, :name => "current 1")
      @current2 = Factory(:sprint, :from_date => Date.today, :to_date => Date.today + 1.days, :project => @project, :name => "current 2")
      @current3 = Factory(:sprint, :from_date => 5.day.ago.to_date, :to_date => Date.today, :project => @project, :name => "current 3")
      @future = Factory(:sprint, :from_date => Date.today + 1.days, :to_date => Date.today + 14.days, :project => @project, :name => "future")
    end

    should "get past sprints only" do
      assert_equal 5, @project.sprints.count
      past_sprints = @project.sprints.past
      assert_equal 1, past_sprints.size
      assert past_sprints.include?(@past)
    end

    should "get current sprints as ongoing" do
      assert_equal 5, @project.sprints.count
      ongoing_sprints = @project.sprints.ongoing
      assert_equal 3, ongoing_sprints.size
      [@current1, @current2, @current3].each do |sprint|
        assert ongoing_sprints.include?(sprint)
      end
    end

    should "get future sprints only" do
      assert_equal 5, @project.sprints.count
      future_sprints = @project.sprints.future
      assert_equal 1, future_sprints.size
      assert future_sprints.include?(@future)
    end
  end

  context "Planning marker assosiated to sprint" do
    setup do
      project = Factory.create(:project)
      @sprint = Factory.create(:sprint, :project => project)
      5.times do
        @sprint.items << Factory.create(:item, :project => project, :sprint => @sprint, :estimate => 3.0)
      end
      @planning_marker = @sprint.planning_marker
    end

    should "return sprint name" do
      assert_equal @sprint.name, @planning_marker.sprint_name
    end

    should "return sum of sprint's items" do
      sum = @sprint.items.map { |item| item.estimate }.inject { |sum, estimate| sum + estimate }
      assert_equal sum, @sprint.items_estimated_effort
      assert_equal sum, @planning_marker.effort
    end

    should "return project that is assosiated to sprint" do
      assert_equal @sprint.project, @planning_marker.project
    end

    should "return sprint's end date" do
      assert_equal @sprint.to_date, @planning_marker.sprint_to_date
    end
  end

  def test_assign_item
    sprint = sprint_with_ordered_items
    old_count = sprint.items.count
    item = backlog_elements(:first)
    assert_nil item.sprint
    sprint.assign_item item
    check_items_order sprint.reload
    assert_equal old_count + 1, sprint.items.count
    assert_equal(sprint.items.count - 1, item.reload.position_in_sprint)
  end

  def test_assign_item_from_different_project
    sprint = sprint_with_ordered_items
    old_count = sprint.items.count
    item = backlog_elements(:item_from_second_project)
    old_sprint = item.sprint
    assert_raise Sprint::ItemFromDifferentProjectAssignmentError do
      sprint.assign_item item
    end
    assert_equal old_count, sprint.reload.items.count
    assert_equal old_sprint, item.reload.sprint
  end

  def test_assign_item_with_infinite_estimate
    sprint = sprint_with_ordered_items
    old_count = sprint.items.count
    item = backlog_elements(:item_with_infinite_estimate)
    old_sprint = item.sprint
    assert_raise Sprint::ItemWithInfiniteEstimateAssignmentError do
      sprint.assign_item item
    end
    assert_equal old_count, sprint.reload.items.count
    assert_equal old_sprint, item.reload.sprint
  end

  private
  def sprint_with_ordered_items
    sprints(:sprint_with_assigned_tasks)
  end

  def check_items_order(sprint)
    sprint.items.each do |item|
      assert_equal sprint.items.index(item), item.reload.position_in_sprint
    end
  end
end

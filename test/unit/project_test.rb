require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :backlog_elements, :users, :role_assignments, :roles, :domains

  #should_have_many :planning_markers

  def setup
    super
    Domain.current = @domain = domains(:code_sprinters)
    @banana = projects(:bananorama)
    @janek = users(:janek)
    @scrum_master = roles(:scrum_master)
    @banana_master = users(:banana_master)
    User.current = users(:user_one)
    @tz = 'Warsaw'
  end
  
  def teardown
    super
    Project.current = nil
    User.current = nil
    Domain.current = nil
  end

  def assert_has_default_preferences(project)
    assert_equal("SP", project.backlog_unit)
    assert_equal("h", project.task_unit)
    assert_equal(14, project.sprint_length)
    assert_equal(Project::FIBONNACI_ESTIMATE.join(","), project.estimate_sequence)
  end

  context "Creating project with assigned roles" do
    setup do 
      @p = Factory.build :project, :domain => Domain.current
      @team_member = roles(:team_member)
      @product_owner = roles(:product_owner)
      @p.users_to_assign = {
        "scrum_master" => { @janek.login => 1, @banana_master.login => 1 },
        "product_owner" => { User.current.login => 1 },
        "team_member" => { @janek.login => 1 }
      }
    end
    
    should "create correct roles" do
      assert_difference "RoleAssignment.count", 4 do
        assert @p.save
      end
      
      janek_roles = @p.get_user_roles(@janek)
      assert_equal 2, janek_roles.length
      assert janek_roles.include?(@scrum_master)
      assert janek_roles.include?(@team_member)
      
      user_one_roles = @p.get_user_roles(User.current)
      assert_equal 1, user_one_roles.length
      assert_equal @product_owner, user_one_roles.first
      
      scrum_master_roles = @p.get_user_roles(@banana_master)
      assert_equal 1, scrum_master_roles.length
      assert_equal @scrum_master, scrum_master_roles.first
    end
  end

  def test_get_items
    p = projects(:bananorama)
    assert_respond_to p, :items
    assert_nothing_raised { b = p.items.count }
  end

  context 'Project.current' do
    should 'be set only to nil or a Project instance' do
      Project.current = nil
      assert_nil Project.current
      assert_raises(RuntimeError) do
        Project.current = 1.2
      end

      assert_nil Project.current

      Project.current = projects(:bananorama)
      assert_equal projects(:bananorama), Project.current

      Project.current = projects(:second)
      assert_equal projects(:second), Project.current

      Project.current = nil
      assert_nil Project.current
    end
  end

  context 'A project instance' do
    setup do
      @project = Project.new :name => "project-name", :description => "Whatever", :presentation_name => "Gruda w błocie", :time_zone => @tz
      @project.domain = @domain
      @project.save!
    end

    should 'have unique name within domain' do
      @another = projects(:bananorama)
      @project.name = @another.name
      assert !@project.valid?
    end

    should 'have same name as another project from different domain' do
      DomainChecks.disable do
        @another = projects(:first_in_abp_domain)
        @project.name = @another.name
        assert_valid @project
        assert_valid @another
      end
    end

    should 'validate project_name format' do
      valid_names = ["project", "project12", "project-name", "my-project", "1243" ]
      invalid_names = ["", "Adam", "a*b", "valid?", "great!", "śmigło" ]

      valid_names.each do |name|
        @project.name = name
        assert_valid @project
      end
      invalid_names.each do |name|
        @project.name = name
        assert !@project.valid?
      end
    end

    should 'set only valid sprint length value' do
      assert_valid(@project)
      for inval in ["rrr", nil, -1, 0, ::Sprint::MAX_LENGTH + 1, 0.6, 50.1]
        @project.sprint_length = inval
        assert_not_valid(@project)
      end

      @project.sprint_length = 13
      assert_valid(@project)
    end

    should 'set time zone' do
      assert_valid @project

      @project.time_zone = "Niematakiegonumeru"
      assert_not_valid @project
      
      @project.time_zone = "Warsaw"
      assert_valid @project
    end

    should 'display time zone' do
      assert_valid @project

      @project.time_zone = "nieistniejemysobie"
      assert_not_valid @project
      assert_equal("", @project.display_timezone)
      
      @project.time_zone = "Warsaw"
      assert_valid @project
      assert_equal("(GMT+01:00) Warsaw", @project.display_timezone)

    end

    should 'have users when role is assigned to it' do
      assert @project.users.empty?
      hash = { :user => users(:janek), :project => @project, :role => roles(:team_member) }
      ra = RoleAssignment.new(hash)
      assert ra.save
      @project.reload
      assert !@project.users.empty?
    end

    should 'add users' do
      user = Factory.create(:user)
      assert_nothing_raised { @project.add_user_with_role(user, @scrum_master) }
      @project.reload
      assert @project.users.include?(user)
    end

    should 'have calendar key' do
      assert_not_nil @project.calendar_key
    end
  end

  context 'A project with users' do
    setup do
      @project = projects(:bananorama)
    end

    should 'get project roles from users' do
      banana_roles = @project.get_user_roles(@banana_master)
      assert banana_roles.include?(roles(:scrum_master)), banana_roles.inspect
    end

    should 'remove all users roles' do
      @project.remove_all_users_roles(@banana_master)
      assert @project.get_user_roles(@banana_master).empty?, "There shuldn't be any users roles"
      assert !@project.users.include?(@banana_master)
    end

    should 'return only team members' do
      role = roles(:team_member)
      @project.team_members.each do |member|
        assert @project.get_user_roles(member).include?(role)
      end
    end
  end

  context 'A project with sprints' do
    setup do
      @project = projects(:project_for_sprints)
    end

    should 'select last sprint' do
      p = @project
      Date.stubs(:current).returns("2008-01-01".to_date)
      assert_equal sprints(:sprint_in_january), p.last_sprint

      # mid-sprint
      Date.stubs(:current).returns("2008-02-10".to_date)
      assert_equal sprints(:sprint_in_february), p.last_sprint
      assert_equal sprints(:sprint_in_february), p.last_sprint

      #between sprints
      Date.stubs(:current).returns("2008-01-30".to_date)
      assert_equal sprints(:sprint_in_january), p.last_sprint

      #between sprints
      Date.stubs(:current).returns("2008-02-28".to_date)
      assert_equal sprints(:sprint_in_february), p.last_sprint

      # before first sprint
      Date.stubs(:current).returns("2007-12-30".to_date)
      assert_equal sprints(:sprint_in_january), p.last_sprint

      # after last sprint
      Date.stubs(:current).returns("2009-12-30".to_date)
      assert_equal sprints(:sprint_in_march), p.last_sprint

      # no sprints at all
      p.sprints.destroy_all

      assert_nil p.last_sprint
    end

    should 'select last sprint based on sequence number, when there are concurrent sprints' do
      p = @project
      from = Date.current
      to = from + 10.days
      first = p.sprints.create({
          :name => "Sprint One",
          :from_date => from,
          :to_date => to,
          :sequence_number => 100
        })

      second = p.sprints.create({
          :name => "Sprint Two",
          :from_date => from,
          :to_date => to,
          :sequence_number => 101
        })

      assert_equal(second, p.last_sprint)
      first.update_attribute(:sequence_number, 102)
      assert_equal(first, p.last_sprint)

    end

    should "display list of sprints to plan" do
      p = @project
      from = Date.current - 1.day
      to = from + 10.days
      3.times do |i|
        first = p.sprints.create({
            :name => "Sprint #{i}",
            :from_date => from,
            :to_date => to,
            :sequence_number => 100 + i
          })
        from, to = to, to + 10.days
      end
      sequence_number = 100
      p.sprints_to_plan.each do |s|
        assert_equal sequence_number, s.sequence_number
        sequence_number += 1
      end
      last = p.last_sprint
      item = Factory(:item, :domain => Domain.current, :project => p, :estimate => 1)
      item.save!
      last.assign_item item
      p.sprints_to_plan.each do |s|
        assert_not_equal last.id, s.id
      end
    end

    should 'have calendar' do
      cal = @project.sprint_calendar
      assert_not_nil cal
      assert_equal @project.sprints.length, cal.events.length
      cal.events.each do |event|
        assert_not_nil @project.sprints.detect {|s| s.from_date == event.dtstart }
      end
    end
    context 'and some backlog elements' do
      setup do
        SortableProductBacklog.disable_callbacks do
          position = 0
          Factory.create(:item, :project => @project, :position => 0).save!
          4.times do
            position += 1
            Factory.create(:item, :project => @project, :position => position + 1, :estimate => 3).save!
            PlanningMarker.new(:project => @project, :position => position).save!
            position += 1
          end
        end
        @sequence_number = @project.sprints.map { |s| s.sequence_number }.max + 1
      end

      should 'return proper result when there are no sprints to plan' do
        @project.sprints.select { |s| s.items.empty? }.each { |s| s.destroy }
        expected_sprints_to_plan_names = (0..4).map { |i| "Sprint #{@sequence_number + i}" }
        sprints_to_plan_names = @project.sprints_to_plan_names
        assert_equal @project.planning_markers.length + 1, sprints_to_plan_names.length
        assert_equal expected_sprints_to_plan_names, sprints_to_plan_names
      end

      should 'return proper results when there are sprints to plan' do
        sprints_to_plan = @project.sprints_to_plan.map { |s| s.name }
        expected_sprints_to_plan_names = (0..4).map { |i| sprints_to_plan[i] or "Sprint #{@sequence_number + i}" }
        sprints_to_plan_names = @project.sprints_to_plan_names
        assert_equal @project.planning_markers.length + 1, sprints_to_plan_names.length
        assert_equal expected_sprints_to_plan_names, sprints_to_plan_names
      end

      should 'return properly set last planning marker' do
        marker = @project.last_planning_marker
        assert_equal @project.sprints_to_plan_names.last, marker.sprint_name
        expected_effort = 0
        @project.backlog_elements.not_assigned.reverse_each do |e|
          break if e.type == 'PlanningMarker'
          expected_effort += (e.estimate.nil? or e.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE) ? 0 : e.estimate
        end
        assert_equal expected_effort, marker.effort
      end

      should 'return properly set last planning marker, when there are no real planning markers' do
        @project.planning_markers.destroy_all
        marker = @project.last_planning_marker
        assert_equal @project.sprints_to_plan_names.last, marker.sprint_name
        effort = @project.items.not_assigned.map { |e| (e.estimate.nil? or e.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE) ? 0 : e.estimate }.sum
        assert_equal effort, marker.effort
      end
    end
  end

  context 'A project with backlog elements' do
    setup do
      @project = projects(:bananorama)
    end

    should 'have access to backlog elements' do
      assert_respond_to @project, :backlog_elements
      assert_nothing_raised { @project.backlog_elements.count }
    end

    should 'calculate estimated effort' do
      expected = @project.estimated_effort
      item = Item.new :user_story => "backlog-user_story", :estimate => 3, :project => @project
      item.save!
      assert_equal expected + item.estimate, @project.estimated_effort
      @project.backlog_elements.each do |i|
        i.destroy
      end
      assert_equal 0, @project.reload.estimated_effort

      expected_sum = @project.estimated_effort
      item = Item.new :user_story => "backlog-user_story", :estimate => 2, :project => @project
      item.save!
      assert_equal expected_sum + item.estimate, @project.reload.estimated_effort

      expected_sum = @project.estimated_effort
      item = Item.new :user_story => "backlog-user_story", :estimate => 0.5, :project => @project
      item.save!
      assert_equal expected_sum + item.estimate, @project.reload.estimated_effort
    end

    should 'have not estimated backlog items' do
      @project.items.destroy_all
      item = Item.new :user_story => "backlog-user_story", :project => @project
      item.save!
      assert_equal 1, @project.not_estimated_backlog_items
    end
  end

  def test_rearrange_items_set_as_first_item
    p = projects(:bananorama)
    items = p.items.not_assigned
    item = items[2]
    item.position =  0
    item.save!
    assert_equal 0, item.position
    check_unassigned_items_order(p)
  end
  
  def test_disabling_sorting_callbacks
    p = projects(:bananorama)
    items = p.items.not_assigned
    first = items.first
    last = items.last
    last.position = 0
    
    SortableProductBacklog.disable_callbacks do
      last.save!
    end
    
    last.reload
    first.reload
    
    assert_equal 0, first.position
    assert_equal 0, last.position
  end

  def test_rearrange_items_set_as_last_item
    p = projects(:bananorama)
    items = p.items.not_assigned
    item = items[2]
    item.position = items.count - 1
    item.save!
    assert_equal items.count - 1, item.position
    check_unassigned_items_order(p)
  end

  def test_rearrange_items_desired_position
    p = projects(:bananorama)
    items = p.items.not_assigned
    item = items[2]
    desired_position = (items.count / 2).to_i
    item.position = desired_position
    item.save!
    assert_equal desired_position, item.position
    check_unassigned_items_order(p)
  end

  def test_rearrange_items_too_big_desired_position_is_treated_as_last
    p = projects(:bananorama)
    items = p.items.not_assigned
    item = items[2]
    item.position = items.count
    item.save!
    item.reload
    assert_equal items.count - 1, item.position
    check_unassigned_items_order(p)
  end

  def test_purge_deletes_project_archived_project
    banana_name = @banana.name
    @banana.archived = true
    @banana.save
    @banana.reload
    assert_nothing_raised do
      @banana.purge!
    end
    project = Domain.current.reload.projects.find :first, :conditions => { :name => banana_name }
    assert_nil project
  end

  # this test previously was checking that it is impossible to delete. changed with #552
  def test_purge_on_non_archived_project
    banana_name = @banana.name
    assert !@banana.archived?
    assert_nothing_raised do
      @banana.purge!
    end
    assert !Domain.current.reload.projects.find(:first, :conditions => { :name => banana_name })
  end

  def test_purge_on_empty_project
    proj = projects(:destroyable)
    proj_name = proj.name
    assert !proj.archived?
    assert_nothing_raised do
      proj.purge!
    end
    Domain.current.reload.projects.find :first, :conditions => { :name => proj_name }
  end

  def test_purge_deletes_clip_attachments
    c = mock()
    c.expects(:destroy_attached_files).times(3)
    @banana.stubs(:clips).returns([c, c, c])
    assert_nothing_raised do
      @banana.purge!
    end
  end

  private
  def check_unassigned_items_order(project)
    items = project.items.not_assigned.reload
    items.each do |item|
      assert_equal items.index(item), item.position
    end
  end
end

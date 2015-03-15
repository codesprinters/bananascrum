require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :backlog_elements, :tasks, :sprints, :projects, :tags
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper

  should_belong_to :locked_by, :sprint, :project
  should_ensure_length_in_range :user_story, (1..255)
  
  def setup
    super
    Domain.current = domains(:code_sprinters)
    User.current = @user_one = users(:user_one)
    @user_two = users(:user_two)
  end
  
  def teardown
    super
    User.current = nil
    Domain.current = nil
  end
  
  context 'done and remaining named scopes' do
    setup do 
      @project = Factory.create(:project)
      @item_done = Factory.create(:item, :project => @project) 
      2.times do
        Factory.create(:task, :item => @item_done, :estimate => 0)
      end
      
      @second_item_done = Factory.create(:item, :project => @project) 
      2.times do
        Factory.create(:task, :item => @second_item_done, :estimate => 0)
      end
      
      @item_without_tasks = Factory.create(:item, :project => @project) 
      
      @item_with_open_tasks = Factory.create(:item, :project => @project) 
      2.times do
        Factory.create(:task, :item => @item_with_open_tasks, :estimate => 0)
      end
      @item_with_open_tasks.tasks.last.update_attribute(:estimate, 5)
    end
    
    should 'return proper values' do
      done_scope = @project.items.done
      remaining_scope = @project.items.remaining
      
      assert_contains done_scope, @item_done
      assert_equal 2, done_scope.size
      assert_contains remaining_scope, @item_without_tasks 
      assert_contains remaining_scope, @item_with_open_tasks
      assert_equal 2, remaining_scope.size
    end
  end
  
  def test_has_task
    item = backlog_elements(:item_with_task)
    assert_not_nil(item)
    assert(item.tasks.length > 0)
  end

  should 'have named scope :not_assigned' do
    items = Domain.current.projects[0].items.not_assigned
    assert_match /sprint_id IS NULL/, items.scope(:find)[:conditions]
    assert_match /position ASC/, items.scope(:find)[:order]
  end

  should 'have named scope :locked' do
    items = Domain.current.projects[0].items.locked
    assert_match /locked_by_id IS NOT NULL/, items.scope(:find)[:conditions]
  end

  should 'validate estimate' do
    item = Item.new
    item.project = projects(:bananorama)
    item.user_story = "Foo"

    valid_estimates = [nil, Item::INFINITY_ESTIMATE_REPRESENTATIVE, 0, 0.5, 50, 100]
    valid_estimates.each do |estimate|
      item.estimate = estimate
      assert item.valid?
    end

    invalid_estimates = [-1, 101, 'lala']
    invalid_estimates.each do |estimate|
      item.estimate = estimate
      assert !item.valid?
    end
  end

  def test_assign_to_sprint
    sprint = sprints(:sprint_one)
    item = backlog_elements(:item_with_task)
    task = tasks(:simple)
    assert_nil item.sprint
    item.sprint = sprint
    
    assert_valid item
    assert_nothing_raised(Exception){ item.save }
    assert_equal sprint, item.sprint
    assert_equal item.sprint_id, item.is_assigned
    tasklog = TaskLog.find(:first, :conditions => {:task_id => task.id}, :order => "timestamp DESC")
    assert_not_nil tasklog
    assert_equal sprint, tasklog.sprint
    assert_equal nil, tasklog.estimate_old
    assert_equal 9, tasklog.estimate_new
  end

  def test_drop_from_sprint
    sprint = sprints(:sprint_with_assigned_tasks)
    item = backlog_elements(:item_assigned)
    task = tasks(:third)
    item.sprint = nil
    assert_valid(item)
    assert_nothing_raised(Exception){ item.save }
    tasklog = TaskLog.find(:first, :conditions => {:task_id => task.id}, :order => "timestamp DESC")
    assert_nil tasklog.estimate_new
    assert_equal 5, tasklog.estimate_old
    assert_equal sprint, tasklog.sprint
    sprint.items.reload
    assert_equal(3, sprint.items.to_a.length)
  end

  def test_can_have_infinite_estimate?
    nilish_on_sprint = backlog_elements(:item_with_nil_estimate_on_sprint)
    assert_equal false, nilish_on_sprint.can_have_infinite_estimate?
    nilish_on_sprint.estimate = 9999
    assert !nilish_on_sprint.valid?
    assert_not_nil nilish_on_sprint.errors.on(:estimate)
    assert(nilish_on_sprint.errors.on(:estimate).include?("value can't be infinite"))
  end

  def test_more_intish_estimate
    nilish = backlog_elements(:item_with_nil_estimate)
    floatish = backlog_elements(:item_with_half_estimate)
    intish = backlog_elements(:first)
    assert_equal "?", nilish.more_intish_estimate
    assert floatish.estimate == floatish.more_intish_estimate
    assert intish.estimate == intish.more_intish_estimate
    assert_kind_of Integer, intish.more_intish_estimate
  end

  def test_description_formatting
    DomainChecks.disable{Item.find(:all)}.each do |item|
      if item.description && item.description.strip != ""
        assert_equal item.description, item.readable_description
      else
        assert_equal item.readable_description, "Description not set"
      end
    end
  end

  def test_belongs_to_project
    item = backlog_elements(:item_assigned)
    assert item.project
    assert_equal projects(:bananorama), item.project
  end
  
  def test_tagging
    tag = tags(:banana)
    item = backlog_elements(:item_assigned)

    newly_created = item.add_tag(tag)

    assert ! newly_created

    item.tags.include? tags(:banana)

    assert_raise(ActiveRecord::RecordInvalid) do
      item.add_tag(tag) #already added
    end

    newly_created = item.add_tag("Tag którego jeszcze nie było")

    assert item.tags.any? {|x| x.name == "Tag którego jeszcze nie było"}
    
    assert newly_created

    assert_raise(ActiveRecord::RecordInvalid) do
      item.add_tag("Tag którego jeszcze nie było") #already added
    end

    item = item.reload

    item.tags.include? tags(:banana)

    assert_raise(ActiveRecord::RecordInvalid) do
      # again cross project tagging
      item.add_tag(tags(:second))
    end

    item.project.tags.create(:name => "Tag, który już był")

    newly_created = item.add_tag "Tag, który już był"
    assert ! newly_created

    assert item.tags.any? {|x| x.name == "Tag, który już był"}
  end

  def test_removing_tags
    item = backlog_elements(:item_assigned)
    assert item.tags.empty?

    tag = tags(:banana)

    item.add_tag(tag)

    item.remove_tag(tag)
    assert item.tags.empty?

    item.add_tag(tag)

    item.remove_tag(tag.name)
    assert item.tags.empty?

    item.add_tag(tag)
    item.add_tag('Jeszcze jeden')

    item.remove_tag(tag)
    assert_equal ['Jeszcze jeden'], item.tags.map {|t| t.name}
  end

  def test_tag_list
    project = projects(:bananorama)
    item = Factory(:item, :domain => Domain.current, :project => project)
    item.save!
    tag_list = %w[tag1 tag2 tag3]
    tag_list.each do |name|
      tag = Tag.new
      tag.name = name
      tag.project = project
      tag.save!
      item.add_tag(tag)
    end
    assert_equal tag_list, item.tag_list.sort
  end
  
  def test_creator
    item = Item.new
    item.project = projects(:bananorama)
    item.user_story = "Testing"
    item.estimate = 3
    item.save!
    
    assert_equal users(:user_one), item.creator
    assert !item.update?
    assert item.logs.size == 1
    
    task = item.tasks.new
    task.summary = "Testing"
    task.estimate = 100
    task.save!
    
    item.reload
    log = item.logs.last
    assert_equal 2, item.logs.size
  end
  
  def test_logs_after_assign_to sprint
    sprint = Sprint.create(:name => "new_sprint", :from_date => Date.today, :to_date => (Date.today + 1), :project => @project)
    item = Item.create(:user_story => "new_backlog", :estimate => 1, :project => @project)
    assert_nil item.sprint
    item.sprint = sprint
    item.save!
    item.reload
    assert_equal sprint, item.sprint
    
    item_log = ItemLog.find(:first, :order => "created_at ASC")
    assert_not_nil item_log
    assert_equal sprint, item_log.sprint
    
    assert !item.update?
    assert_equal 1, item.item_logs.size
    item.description = "Testing"
    item.save!
    item.reload
    assert_equal 2, item.item_logs.size
  end
  
  def test_logs_after_drop_from_sprint
    sprint = Sprint.new
    sprint.project = projects(:bananorama)
    sprint.name = "new_sprint"
    sprint.from_date = Date.today
    sprint.to_date = (Date.today + 1)
    sprint.save!
    
    item = Item.new
    item.project = projects(:bananorama)
    item.sprint = sprint
    item.user_story = "Testing"
    item.estimate = 3
    item.save!
   
    item.sprint = nil
    item.save!
    item.reload
    assert_equal 2, item.logs.size
    item.description = "Testing"
    item.save!
    item.reload
    assert_equal 3, item.logs.size
  end

  def test_rearrange_tasks_assign_nil
    item = create_item_with_tasks
    task = item.tasks[0]
    task.position = nil
    task.save!
    task.reload
    check_tasks_order item.reload
    assert_equal item.tasks.count - 1, task.position
  end

  def test_rearrange_tasks_set_as_first_task
    item = create_item_with_tasks
    task = item.tasks[2]
    task.position = 0
    task.save!
    task.reload
    
    check_tasks_order item.reload
    assert_equal 0, task.position
  end

  def test_rearrange_tasks_set_as_last
    item = create_item_with_tasks
    task = item.tasks[2]
    task.position =  item.tasks.count - 1
    task.save!
    task.reload
    check_tasks_order item.reload
    assert_equal(item.tasks.count - 1, task.position)
  end

  def test_rearrange_tasks_desired_position
    item = create_item_with_tasks
    task = item.tasks[-1]
    desired_position = (item.tasks.count / 2).to_i
    task.position = desired_position
    task.save!
    task.reload
    check_tasks_order item.reload
    assert_equal desired_position, task.position
  end

  def test_rearrange_tasks_too_big_desired_position_is_treated_as_last
    item = create_item_with_tasks
    task = item.tasks[0]
    desired_position = item.tasks.count + 10
    task.position = desired_position
    task.save
    task.reload
    
    check_tasks_order item.reload
    assert_equal(item.tasks.count - 1, task.position)
  end

  def test_rearrage_tasks_too_small_desired_position_is_treated_as_first
    item = create_item_with_tasks
    task = item.tasks[-1]
    task.position = -10
    task.save!
    task.reload
    check_tasks_order item.reload
    assert_equal(0, task.position)
  end

  private
  
  def create_item_with_tasks
    item = Item.new
    item.project = projects(:bananorama)
    item.user_story = 'As role I can action'
    item.save!

    5.times do |i|
      task = Task.new
      task.estimate = i
      task.summary = "#{i}"
      task.position = i + 10
      task.item = item
      task.save!
    end

    return item
  end

  def check_tasks_order item
    item.tasks.each do |task|
      assert_equal item.tasks.index(task), task.position
    end
  end
end

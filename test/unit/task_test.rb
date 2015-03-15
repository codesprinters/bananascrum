require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < ActiveSupport::TestCase
  fixtures :tasks, :backlog_elements, :users, :projects

  should_validate_presence_of :item
  should_ensure_length_in_range :summary, (1..255)

  def setup
    super
    Domain.current = domains(:code_sprinters)
    User.current = users(:user_one)
    @item = backlog_elements(:first)
  end

  def teardown
    super
    Domain.current = nil
    User.current = nil
  end
  
  
  def test_get_item
    task = tasks(:simple)
    assert_not_nil(task)
    assert_not_nil(task.item)
  end

  def test_numericality_of_estimate
    task = Task.new(:summary => "sum", :item => @item)
    task.estimate = "string"
    assert !task.valid?
    task.estimate = 9.5
    assert !task.valid?
    task.estimate = 9
    assert task.valid?
    task.estimate = -10
    assert !task.valid?
    task.estimate = 1000
    assert !task.valid?
  end

  def test_update_estimate_change_in_log
     task = tasks(:third)
     old_count = task.task_logs.count
     task.estimate = 9
     task.save
     task.reload
     assert_equal old_count+1, task.task_logs.count
     task_log = task.task_logs.find(:first, :order => "timestamp DESC")
     assert_equal 9, task_log.estimate_new
     assert_not_nil task_log.sprint
     assert_equal task.item.sprint, task_log.sprint
  end
  
  def test_task_done
    task = tasks(:third)
    task.estimate = 0
    task.save
    task.reload
    task.is_done
    assert task.is_done
  end

  def test_user_assignment
    task = tasks(:task_for_user)
    user1 = users(:user_one)
    user2 = users(:user_two)
    assert_not_nil user1, task
    
    assert task.users.blank?
    
    assert_difference 'TaskUser.count' do
      task.assign_users([ user1 ])
    end
    assert ! task.users.blank?
    assert task.valid?
        
    assert_difference 'TaskUser.count', -1 do
      task.assign_users([])
    end
    assert task.valid?
    assert task.users.blank?
        
    assert_difference 'TaskUser.count' do
      task.assign_users([user1])
    end
    assert ! task.users.blank?
    
    task.assign_users([user1, user2])
    assert_equal 2, task.users.length

    #nothing should change as we already have this user asigned
    assert_no_difference 'TaskUser.count' do
      task.assign_users([user1, user2])
    end
    assert_equal 2, task.users.length
  end

  def test_update_log_after_create_task
    task = Task.new(:summary => "sum", :item => @item, :estimate => 5)
    task.save
    task.reload
    assert task.task_logs.blank?
    assert_equal 5, task.estimate
  end
end

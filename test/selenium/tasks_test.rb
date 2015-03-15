require File.dirname(__FILE__) + "/selenium_helper"

class TasksTest < SeleniumTestCase
  def test_add_new_task_on_backlog
    open_backlog_page
    login

    expand_item
    click "link=New task"
    type "summary_16", "another task"
    type "estimate_16", "4"
    click "//input[@name='commit' and @value='Create']"
    assert_text_present "another task"
  end

  def test_add_new_task_on_sprint_page
    open_sprint_page
    login

    expand_item
    click "link=New task"
    wait_for 'isElementPresent("summary_19")'
    type "summary_19", "super new task"
    type "estimate_19", "9"
    click "commit"
    select "filter", "label=All"
    assert_visible "//li[@id='item-20']/span"
    assert_text_present "super new task"
    wait_for 'getText("//div[@id=\'main-panel\']/h2[3]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 32 SP, 9 tasks, 49 h"'
  end

  def test_add_new_task_on_planning_page
    open_planning_page
    login

    # Add task in sprint backlog section
    expand_item "User Story 28" # expand item-28
    click "//ul[@id='submenu_28']/li[1]/form/a" # click add new task for item-28
    type "summary_28", "task super"
    type "estimate_28", "3"
    click "commit"
    # Add task in product backlog section
    assert_text_present "task super"


    expand_item "User Story 3" # expand item-3
    click "//ul[@id='submenu_3']/li[1]/form/a" # click add new task for item-3
    type "summary_3", "tests"
    type "estimate_3", "5"
    click '//li[@id="item-3"]//input[@name="commit"]' # click commit?
    wait_for 'isElementPresent("//div[@id=\'main-panel\']/h2[1]/table/tbody/tr/td[2]")'
    wait_for 'getText("//div[@id=\'main-panel\']/h2[1]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 32 SP, 9 tasks, 43 h"'
  end

  def test_edit_task_on_backlog
    open_backlog_page
    login

    expand_item "User Story 3" # expand item-3
    edit_task_summary("//li[@id='task-1']", "edited task")
    edit_task_estimate("//li[@id='task-1']", "7")
    assert_task("task-1", "edited task", "7 h", "user_3")
  end

  def test_edit_task_on_planning_page
    open_planning_page
    login

    # Edit task in sprint section
    expand_item # expand first item on planning page
    edit_task_summary("//li[@id='task-5']", "new name for 5 task")
    edit_task_estimate("//li[@id='task-5']", "12")

    assert_task("task-5", "new name for 5 task", "12 h", "user_2")
    
    # Edit task in backlog section
    expand_item "User Story 3" # expand item-3
    edit_task_summary("//li[@id='task-1']", "new name for task 1")
    edit_task_estimate("//li[@id='task-1']", "12")
    assert_task("task-1", "new name for task 1", "12 h", "user_3")
  end

  def test_edit_task_on_sprint_page
    open_sprint_page
    login

    expand_item #Expand first item on list
    edit_task_summary("//li[@id='task-5']", "new name for 5 task")
    edit_task_estimate("//li[@id='task-5']", "20")
    assert_task("task-5", "new name for 5 task", "20 h", "user_2")
  end

  def test_delete_task_on_backlog_page
    open_backlog_page
    login

    expand_item "User Story 3" # expand item-3
    wait_for 'isElementPresent("//li[@id=\'item-3\']/div[2]/ul[3]/li/div/img")'
    click "//li[@id='item-3']/div[2]/ul[3]/li/div/img" # click in delete task-1
    sleep 3
    assert /^Are you sure you want to delete 'Task 1' [\s\S]$/ =~ get_confirmation
    sleep 6
    assert_element_not_present "task-1"
  end

  def test_delete_task_on_planning_page
    open_planning_page
    login

    expand_item "User Story 3" #expand item-3
    click "//li[@id='item-3']/div[2]/ul[3]/li/div/img" # click delete task-1
    sleep 3
    assert /^Are you sure you want to delete 'Task 1' [\s\S]$/ =~ get_confirmation

    wait_for 'isElementPresent("//li[@id=\'item-21\']/a")'
    assert_element_not_present "task-1"

    expand_item "User Story 21" #expand item-21
    wait_for 'isElementPresent("//li[@id=\'item-21\']/div[2]/ul[3]/li/div/img")'
    click "//li[@id='item-21']/div[2]/ul[3]/li/div/img" #click delete task-10
    assert /^Are you sure you want to delete 'Task 10' [\s\S]$/ =~ get_confirmation

    assert_element_not_present "task-10"
  end

  def test_bulk_add_checkbox
    open_backlog_page
    login

    expand_item "User Story 16"
    wait_for 'isElementPresent("link=New task")'
    click "link=New task"
    wait_for 'isElementPresent("//input[@id=\'summary_16\']")'
    type "//input[@id='summary_16']", "New task summary"
    type "//input[@id='estimate_16']", "3"
    click "//input[@id='leave-open']"
    click "//input[@name='commit' and @value='Create']"
    assert_text_present "New task summary"
    assert_visible "//div[@class='new-task form-container']"
    wait_for 'getText("//input[@id=\'summary_16\']").normalize() == ""'
    wait_for 'getText("//input[@id=\'estimate_16\']").normalize() == ""'
  end

  def test_add_task_with_many_users
    open_sprint_page
    login

    expand_item "User Story 24"

    assign_users_to_task "Task 12", "user_1", "user_2", "user_3"

    assert_task("task-12", "Task 12", "8 h", "user_1, user_2, user_3")

    open_sprint_page

    expand_item "User Story 24"

    assert_task("task-12", "Task 12", "8 h", "user_1, user_2, user_3")
  end

  def test_edit_assigned_users_in_task
    open_sprint_page
    login

    expand_item #Expand first item on list

    assign_users_to_task "Task 5", "user_1", "user_2", "user_3"

    assert_task("task-5", "Task 5", "10 h", "user_1, user_3")

    open_sprint_page
    expand_item #Expand first item on list
    assert_task("task-5", "Task 5", "10 h", "user_1, user_3")
  end

end


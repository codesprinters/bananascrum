require File.dirname(__FILE__)  + "/selenium_helper"

class FilterTest < SeleniumTestCase

  def test_filter_tasks
    open_sprint_page
    login

    select "filter", "label=user_1"
    assert_visible "//li[@id='item-20']/span"
    assert_not_visible "//li[@id='item-23']/span"

    select "filter", "label=user_2"
    assert_visible "//li[@id='item-19']/span"

    select "filter", "label=user_3"
    assert_not_visible "//li[@id='item-19']/span"
    assert_not_visible "//li[@id='item-20']/span"

    select "filter", "label=All"
    assert_visible "//li[@id='item-20']/span"

    select "filter", "label=unassigned"
    assert_visible "//li[@id='item-21']/span"
    assert_visible "//li[@id='item-24']/span"
  end

  def test_change_assigned_user_in_filtered_task
    open_sprint_page
    login

    select "filter", "label=unassigned"

    wait_for 'isVisible("//li[@id=\'item-21\']/span")'
    assert_visible "//li[@id='item-21']/span"
    assert_visible "//li[@id='item-24']/span"
    expand_item "User Story 24"

    assign_users_to_task "Task 12", "user_2"
    
    assert_not_visible "//li[@id='item-24']/span"

    select "filter", "label=user_2"
    wait_for 'isVisible("//li[@id=\'item-19\']/div/span")'
    assert_visible "//li[@id='item-19']/span"
    assert_visible "//li[@id='item-24']/span"

    select "filter", "label=All"
    wait_for 'isVisible("//li[@id=\'item-20\']/div/span")'
    assert_visible "//li[@id='item-20']/span"
    assert_visible "//li[@id='item-19']/span"
    assert_visible "//li[@id='item-24']/span"
  end
end
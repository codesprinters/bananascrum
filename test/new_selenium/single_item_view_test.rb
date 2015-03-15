require File.dirname(__FILE__) + "/selenium_helper"

class ImpedimentsTest < SeleniumTestCase


  def test_edit_in_single_item_view
    open_backlog_page
    login

    #Change Item User Story
    click "//li[@id='item-16']//div[contains(@class, 'item-user-story')]"
    type "//li[@id='item-16']//input[@type='text']", "edited something"
    click "//div[@class='submit-cancel-container']//button[@type='submit']"
    assert_text_present "edited something"
    assert_text_not_present("User Story 16")

    #Add Task
    expand_item
    click "link=New task"
    sleep 1
    type "//p[@class='new-task-summary']//input[@type='text']", "another task"
    type "estimate_16", "4"
    click "//input[@name='commit' and @value='Create']"
    assert_text_present "another task"

    #Open single item view
    click "link=Open in new tab"
    wait_for_pop_up "", "30000"
    select_window "name=undefined"
    sleep 2

    #Assert item history
    assert_text_present "John Doe changed item user story from 'User Story 16' to 'edited something'"
    assert_text_present "John Doe created task 'another task' with estimate 4"

    #Add new task in single item view
    click "link=New task"
    type "//p[@class='new-task-summary']//input[@type='text']", "some single task"
    type "//input[@class='new-task-estimate']", "33"
    click "commit"
    assert_text_present "some single task"

    #Add new comment in single item view
    type "comment_text", "some single comment"
    click "//input[@name='commit' and @value='Post comment']"
    assert_text_present "some single comment"

    #Change Item user story
    click "//span[contains(@class, 'item-user-story')]"
    type "//input[@type='text']", "single edited something"
    click "//div[@class='submit-cancel-container']//button[@type='submit']"
    assert_text_present "single edited something"
   
    #Edit item description
    click "//div[contains(@class, 'item-description-text')]"
    sleep 2
    type "//div[@class='item-description-text']//textarea", "edited single item description"
    click "//button[@type='submit']"
    assert_text_present "edited single item description"

  end
end
require File.dirname(__FILE__) + "/selenium_helper"

class ItemsTest < SeleniumTestCase
  def test_add_item
    open_backlog_page
    login

    click "link=New backlog item"
    fill_form("new_item")
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("//li[@id=\'item-29\']/span")'
    wait_for 'getText("//li[@id=\'item-29\']/span").normalize() == "some new user story"'
    expand_item
    wait_for 'getText("items-count").normalize() == "Total: 17 items, 2 not estimated, 48 SP"'
    logout
  end

  def test_add_item_empty_user_story
    open_backlog_page
    login

    click "link=New backlog item"
    click "//input[@name='commit' and @value='Create']"
    assert_text_not_present("some new user story")
    wait_for 'isElementPresent("//div[@id=\'errorExplanation\']/ul/li")'
    wait_for 'getText("//div[@id=\'errorExplanation\']/ul/li").normalize() == "User story can\'t be blank"'
    logout
  end

  def test_change_user_story_name
    open_backlog_page
    login

    click "//li[@id='item-2']/span"
    type "//li[@id='item-2']/span/form/input", "edited something"
    click "//button[@type='submit']"
    wait_for 'getText("//li[@id=\'item-2\']/span").normalize() == "edited something"'
    assert_text_not_present("User Story 2")
    logout
  end

  def test_change_estimates_1
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-4']/div/span"
    select "//li[@id='item-4']/div/span/form/select", "label=0.5"
    wait_for 'isElementPresent("//li[@id=\'item-4\']/div[1]/span")'
    wait_for 'getText("//li[@id=\'item-4\']/div[1]/span").normalize() == "0.5"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46.5 SP"'
    logout
  end

  def test_change_estimates_2
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-4']/div/span"
    select "//li[@id='item-4']/div/span/form/select", "label=3"
    wait_for 'isElementPresent("//li[@id=\'item-4\']/div[1]/span")'
    wait_for 'getText("//li[@id=\'item-4\']/div[1]/span").normalize() == "3"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 49 SP"'
    logout
  end

  def test_change_estimates_for_two_items
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-5']/div/span"
    select "//li[@id='item-5']/div/span/form/select", "label=5"
    wait_for 'isElementPresent("//li[@id=\'item-5\']/div[1]/span")'
    wait_for 'getText("//li[@id=\'item-5\']/div[1]/span").normalize() == "5"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 48 SP"'
    click "//li[@id='item-7']/div/span"
    select "//li[@id='item-7']/div/span/form/select", "label=100"
    wait_for 'getText("//li[@id=\'item-7\']/div[1]/span").normalize() == "100"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 135 SP"'
    logout
  end

  def test_change_estimates_from_unknown
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-1']/div/span"
    select "//li[@id='item-1']/div/span/form/select", "label=3"
    wait_for 'getText("//li[@id=\'item-1\']/div[1]/span").normalize() == "3"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 1 not estimated, 49 SP"'
    logout
  end

  def test_change_estimates_to_unknown
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-2']/div/span"
    select "//li[@id='item-2']/div/span/form/select", "label=?"
    wait_for 'getText("//li[@id=\'item-2\']/div[1]/span").normalize() == "?"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 3 not estimated, 45 SP"'
    logout
  end

  def test_change_estimates_to_infinity
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-2']/div/span"
    select "//div/span/form/select", "label=∞"
    wait_for 'isElementPresent("//li[@id=\'item-2\']/div[1]/span")'
    wait_for 'getText("//li[@id=\'item-2\']/div[1]/span").normalize() == "∞"'
    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 45 SP"'
    logout
  end

  def test_delete_item
    open_backlog_page
    login

    wait_for 'getText("items-count").normalize() == "Total: 16 items, 2 not estimated, 46 SP"'
    click "//li[@id='item-6']/div/img"
    assert /^Are you sure you want to delete 'User Story 6' [\s\S]$/ =~ get_confirmation
    wait_for 'getText("items-count").normalize() == "Total: 15 items, 2 not estimated, 41 SP"'
    logout
  end

  def test_add_item_to_sprint
    open_planning_page
    login

    wait_for 'isElementPresent("//li[@id=\'item-3\']/div[1]/img[2]")'
    click "//li[@id='item-3']/div[1]/img[2]"
    sleep 3
    wait_for 'isElementPresent("link=Sprint")'
    click_and_wait "link=Sprint"
    wait_for 'isElementPresent("filter")'
    select "filter", "label=All"
    wait_for 'isVisible("//li[@id=\'item-20\']/span")'
    assert_text_present "User Story 3"
    wait_for 'isElementPresent(\'item-3\')'
    wait_for 'getText("//div[@id=\'main-panel\']/h2[3]/table/tbody/tr/td[2]").normalize() == "Total: 11 items, 1 not estimated, 33 SP, 9 tasks, 48 h"'
    logout
  end

  def test_drop_item_from_sprint_on_planning_page
    open_planning_page
    login

    wait_for 'isElementPresent("//li[@id=\'item-25\']/div/img[3]")'
    click "//li[@id='item-25']/div/img[3]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    sleep 5
    wait_for 'isElementPresent("link=Backlog")'
    click_and_wait "link=Backlog"
    wait_for 'isElementPresent("//li[@id=\'item-25\']")'
    assert_element_present "item-25"
    logout
  end

  def test_drop_item_from_sprint_on_sprint_page
    open_sprint_page
    login
    wait_for 'isElementPresent("//li[@id=\'item-26\']/div/img[3]")'
    click "//li[@id='item-26']/div/img[3]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    wait_for 'isElementPresent("link=Backlog")'
    assert_element_not_present("item-26")
    open_backlog_page
    assert_element_present("item-26")
    logout
  end

  def test_drop_and_add_that_same_item
    open_planning_page
    login

    wait_for 'isElementPresent("//li[@id=\'item-25\']/div/img[3]")'
    click "//li[@id='item-25']/div/img[3]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    sleep 5
    wait_for 'isElementPresent("//li[@id=\'item-25\']/div[1]/img[2]")'
    click "//li[@id='item-25']/div[1]/img[2]"
    sleep 3
    wait_for 'isElementPresent("link=Sprint")'
    click_and_wait "link=Sprint"
    wait_for 'isElementPresent("//li[@id=\'item-25\']/")'
    assert_text_present "User Story 25"
    logout
  end

  def test_watermark_in_new_item_form
    open_backlog_page
    login

    click "link=New backlog item"

    # ensure watermarks present on form load
    assert_value("//textarea[@id=\'item_description\']", "*Acceptance criteria*\n\nI do this ...\nThis happens ...")
     
    # ensure no watermarks are present after clicking on the fields
    click "//input[@id=\'item_user_story\']"
    assert_value("//input[@id=\'item_user_story\']", "")
    click "//textarea[@id=\'item_description\']"
    assert_value("//textarea[@id=\'item_description\']", "")
    logout
  end

  #FIXME: WZOLNOWSKI move this to long term view selenium
  def skipped_test_backlog_planning
    open_backlog_page
    login

    click 'long-term-view-toggle'
    type "velocity", "18"
    click "commit"
    wait_for 'isElementPresent("//ul[@id=\'backlog-items\']/li[5]/div[@class=\'marker-info\']")'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[5]/div[@class=\'marker-info\']").normalize() == "Sprint 3 18 SP"'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[12]/div[@class=\'marker-info\']").normalize() == "Sprint 4 18 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 5 10 SP"'

    type "velocity", "20"
    click "commit"
    wait_for 'isElementPresent("//ul[@id=\'backlog-items\']/li[5]/div[@class=\'marker-info\']")'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[5]/div[@class=\'marker-info\']").normalize() == "Sprint 3 18 SP"'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[12]/div[@class=\'marker-info\']").normalize() == "Sprint 4 18 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 5 10 SP"'

    type "velocity", "21"
    click "commit"
    wait_for 'isElementPresent("//ul[@id=\'backlog-items\']/li[7]/div[@class=\'marker-info\']")'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[7]/div[@class=\'marker-info\']").normalize() == "Sprint 3 21 SP"'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[13]/div[@class=\'marker-info\']").normalize() == "Sprint 4 20 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 5 5 SP"'

    type "velocity", "45"
    click "commit"
    wait_for 'isElementPresent("//ul[@id=\'backlog-items\']/li[15]/div[@class=\'marker-info\']")'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[15]/div[@class=\'marker-info\']").normalize() == "Sprint 3 45 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 1 SP"'

    type "velocity", "46"
    click "commit"
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 3 46 SP"'

    type "velocity", "47"
    click "commit"
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 3 46 SP"'
  end

 def test_bulk_add_item
    open_backlog_page
    login

    wait_for 'isElementPresent("link=Bulk add")'
    click "link=Bulk add"
    wait_for 'isElementPresent("text")'
    type "text", "Test item 1\n- test task 1\n- test task 2\nTest item with estimate, 17\n- test task 3\nNext item"
    click "//input[@name='commit' and @value='Create']"

    wait_for 'isElementPresent("//li[@id=\'item-31\']/span")'
    assert_equal "Test item 1", get_text("//li[@id='item-31']/span")
    assert_equal "17", get_text("//li[@id='item-30']/div[1]/span")
    assert_equal "Test item with estimate", get_text("//li[@id='item-30']/span")
    assert_equal "Next item", get_text("//li[@id='item-29']/span")


    click "//div[@class=\'expandable-list\']//li[@id=\'item-31\']//div[@class=\'icon expand-icon expand\']"
    assert_task("task-13", "test task 3", "1 h", "unassigned")
    click "//div[@class=\'expandable-list\']//li[@id=\'item-30\']//div[@class=\'icon expand-icon expand\']"
    assert_task("task-14", "test task 1", "1 h", "unassigned")
    assert_task("task-15", "test task 2", "1 h", "unassigned")

    open_backlog_page
    click "//div[@class=\'expandable-list\']//li[@id=\'item-31\']//div[@class=\'icon expand-icon expand\']"
    assert_task("task-13", "test task 3", "1 h", "unassigned")
    click "//div[@class=\'expandable-list\']//li[@id=\'item-30\']//div[@class=\'icon expand-icon expand\']"
    assert_task("task-14", "test task 1", "1 h", "unassigned")
    assert_task("task-15", "test task 2", "1 h", "unassigned")
  end
end

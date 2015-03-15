require File.dirname(__FILE__) + "/selenium_helper"

class ItemsTest < SeleniumTestCase

  def test_add_item
    open_backlog_page
    login

    click "link=Add item"
    fill_form("new_item")
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("//li[@id=\'item-29\']/")'
    assert_text_present "some new user story"
    assert_backlog_stats("17", "2", "48")
  end

  def test_add_item_empty_user_story
    open_backlog_page
    login

    click "link=Add item"
    click "//input[@name='commit' and @value='Create']"
    assert_text_not_present("some new user story")
    wait_for 'isElementPresent("//div[@id=\'errorExplanation\']/ul/li")'
    wait_for 'getText("//div[@id=\'errorExplanation\']/ul/li").normalize() == "User story can\'t be blank"'
    logout
  end

  def test_change_user_story_name
    open_backlog_page
    login

    click "//li[@id='item-2']//div[contains(@class, 'item-user-story')]"
    type "//li[@id='item-2']//input[@type='text']", "edited something"
    click "//div[@class='submit-cancel-container']//button[@type='submit']"
    assert_text_present "edited something"
    assert_text_not_present("User Story 2")
    logout
  end

  def test_change_estimates_1
    open_backlog_page
    login

    click "//li[@id='item-4']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-4']//select", "label=0.5"
    wait_for 'getText("//li[@id=\'item-4\']//div[@class=\'item-estimate-container\']/span").normalize() == "0.5"'
    assert_backlog_stats("16", "2", "46.5")
  end

  def test_change_estimates_2
    open_backlog_page
    login

    click "//li[@id='item-4']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-4']//select", "label=3"
    wait_for 'getText("//li[@id=\'item-4\']//div[@class=\'item-estimate-container\']/span").normalize() == "3"'
    assert_backlog_stats("16", "2", "49")
  end

  def test_change_estimates_for_two_items
    open_backlog_page
    login

    click "//li[@id='item-5']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-5']//select", "label=5"
    wait_for 'getText("//li[@id=\'item-5\']//div[@class=\'item-estimate-container\']/span").normalize() == "5"'
    assert_backlog_stats("16", "2", "48")
    click "//li[@id='item-7']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-7']//select", "label=100"
    wait_for 'getText("//li[@id=\'item-7\']//div[@class=\'item-estimate-container\']/span").normalize() == "100"'
    assert_backlog_stats("16", "2", "135")
  end

  def test_change_estimates_from_unknown
    open_backlog_page
    login

    click "//li[@id='item-1']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-1']//select", "label=3"
    wait_for 'getText("//li[@id=\'item-1\']//div[@class=\'item-estimate-container\']/span").normalize() == "3"'
    assert_backlog_stats("16", "1", "49")
  end

  def test_change_estimates_to_unknown
    open_backlog_page
    login

    click "//li[@id='item-2']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-2']//select", "label=?"
    wait_for 'getText("//li[@id=\'item-2\']//div[@class=\'item-estimate-container\']/span").normalize() == "?"'
    assert_backlog_stats("16", "3", "45")
  end

  def test_change_estimates_to_infinity
    open_backlog_page
    login

    click "//li[@id='item-2']//span[contains(@class, 'item-estimate')]"
    select "//li[@id='item-2']//select", "label=∞"
    wait_for 'getText("//li[@id=\'item-2\']//div[@class=\'item-estimate-container\']/span").normalize() == "∞"'
    assert_backlog_stats("16", "2", "45")
  end

  def test_delete_item
    open_backlog_page
    login

    click "//li[@id='item-6']//img[@alt='Delete this backlog item']"
    assert /^Are you sure you want to delete 'User Story 6' [\s\S]$/ =~ get_confirmation
    assert_backlog_stats("15", "2", "41")
  end


  def test_add_item_to_sprint
    open_planning_page
    login

    click "//li[@id='item-3']//img[contains(@class, 'assign-arrow')]"
    sleep 3
    open_sprint_page
    select "filter", "label=All"
    assert_text_present "User Story 3"
    wait_for 'isElementPresent(\'item-3\')'
    logout
  end

  def test_drop_item_from_sprint_on_planning_page
    open_planning_page
    login

    click "//li[@id='item-25']//img[contains(@class, 'drop-arrow')]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    sleep 5
    open_backlog_page
    assert_element_present "item-25"
    logout
  end

  def test_drop_item_from_sprint_on_sprint_page
    open_sprint_page
    login
    click "//li[@id='item-26']//img[contains(@class, 'drop-arrow')]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    sleep 2
    assert_element_not_present("item-26")
    open_backlog_page
    assert_element_present("item-26")
    logout
  end

  def test_drop_and_add_that_same_item
    open_planning_page
    login

    click "//li[@id='item-25']//img[contains(@class, 'drop-arrow')]"
    sleep 3
    assert /^Are you sure you want to drop this item to backlog[\s\S]$/ =~ get_confirmation
    sleep 5
    click "//li[@id='item-25']//img[contains(@class, 'assign-arrow')]"
    sleep 3
    open_sprint_page
    wait_for 'isElementPresent("//li[@id=\'item-25\']/")'
    assert_text_present "User Story 25"
    logout
  end

  def test_watermark_in_new_item_form
    open_backlog_page
    login

    click "link=Add item"

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

    wait_for 'isElementPresent("//li[@id=\'item-31\']")'
    assert_equal "Test item 1", get_text("//li[@id='item-31']//div[contains(@class, 'item-user-story')]")
    assert_equal "Test item with estimate", get_text("//li[@id='item-30']//div[contains(@class, 'item-user-story')]")
    assert_equal "Next item", get_text("//li[@id='item-29']//div[contains(@class, 'item-user-story')]")
  end
end

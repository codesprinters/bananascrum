require File.dirname(__FILE__) + "/selenium_helper"

class DragAndDropTest < SeleniumTestCase


  def item_drag_and_drop (dragged_element, destination_element)
    sleep 3
    mouse_down_at dragged_element, "10, 10"
    sleep 3
    mouse_move_at destination_element, "10, 19"
    sleep 3
    mouse_up_at destination_element, "10, 19"
    sleep 2
  end

  def item_drag_and_drop_plan (dragged_element, destination_element)
    sleep 3
    mouse_down_at dragged_element, "10, 10"
    sleep 3
    mouse_move_at destination_element, "20, 7"
    sleep 3
    mouse_move_at destination_element, "20, 5"
    sleep 3
    mouse_up_at destination_element, "20, 5"
    sleep 2
  end

  # TESTS START HERE:

  def test_sort_item_on_sprint_page
    open_sprint_page
    login

    assert_equal "User Story 19", get_text("//ul[@id='assigned-backlog-items']/li[1]/span")
  
    item_drag_and_drop("//*[@id=\"item-19\"]", "//*[@id=\"item-21\"]")
  
    assert_equal "User Story 19", get_text("//ul[@id='assigned-backlog-items']/li[3]/span")
    click_and_wait "link=Backlog"
    click_and_wait "link=Sprint"
    assert_equal "User Story 19", get_text("//ul[@id='assigned-backlog-items']/li[3]/span")
  end

  # FIXME: WZOLNOWSKI , move this to check timeline view
  def skip_test_sort_item_on_backlog_page
    open_backlog_page
    login
  
    click 'long-term-view-toggle'
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[1]/span").normalize() == "User Story 16"'
  
    item_drag_and_drop("//*[@id=\"item-16\"]", "//*[@id=\"item-14\"]")
  
    wait_for 'getText("//ul[@id=\'backlog-items\']/li[3]/span").normalize() == "User Story 16"'
    click_and_wait "link=Sprint"
    click_and_wait "link=Backlog"
#TODO  fir this
  #  wait_for 'getText("//ul[@id=\'backlog-items\']/li[4]/span").normalize() == "User Story 16"'
  end
  
  def test_plan_sprint
    open_planning_page
    login
  
    assert_equal "User Story 13", get_text("//ul[@id='backlog-items']/li[4]/span")
  
    item_drag_and_drop_plan("//li[@id='item-13']", "//li[@id='item-23']")
  
    assert_equal "User Story 13", get_text("//ul[@id='assigned-backlog-items']/li[6]/span")
  
    assert_equal "User Story 27", get_text("//ul[@id='assigned-backlog-items']/li[11]/span")
  
    item_drag_and_drop_plan("//li[@id='item-27']", "//li[@id='item-10']")
  
    assert_equal "User Story 27", get_text("//ul[@id='backlog-items']/li[6]/span")
  
    click_and_wait "link=Backlog"
  
    wait_for 'isElementPresent("//li[@id=\'item-27\']/")'
  
    sleep 3
    click_and_wait "link=Sprint"
  
    wait_for 'isElementPresent("//li[@id=\'item-13\']/")'
  end

  # FIXME: WZOLNOWSKI , move this to check timeline view
  def skip_test_markers_sorting
    open_backlog_page
    login

    click 'long-term-view-toggle'

    wait_for "isElementPresent(\"//ul[@id='backlog-items']/li[1]/div[2]\")"
    assert_equal "User Story 16", get_text("//ul[@id='backlog-items']/li[1]/span")

    item_drag_and_drop_plan("//ul[@id='planning-marker-top']/li[1]", "//*[@id='item-14']") # add marker

    wait_for 'getText("//ul[@id=\'backlog-items\']/li[3]/div[@class=\'marker-info\']").normalize() == "Sprint 3 0 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 46 SP"'

    click_and_wait "link=Sprint"
    click_and_wait "link=Backlog"

    wait_for 'getText("//ul[@id=\'backlog-items\']/li[3]/div[@class=\'marker-info\']").normalize() == "Sprint 3 0 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 46 SP"'

    item_drag_and_drop_plan("//ul[@id='backlog-items']/li[3]", "//*[@id=\"item-3\"]") # move marker

    wait_for 'getText("//ul[@id=\'backlog-items\']/li[15]/div").normalize() == "Sprint 3 45 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 1 SP"'

    click_and_wait "link=Sprint"
    click_and_wait "link=Backlog"

    wait_for 'getText("//ul[@id=\'backlog-items\']/li[15]/div").normalize() == "Sprint 3 45 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 1 SP"'

    # add new item
    click "link=New backlog item"
    fill_form("new_item")
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("//li[@id=\'item-30\']/span")'
    wait_for 'getText("//li[@id=\'item-30\']/span").normalize() == "some new user story"'
    wait_for 'getText("items-count").normalize() == "Total: 17 items, 2 not estimated, 48 SP"'

    wait_for 'getText("//ul[@id=\'backlog-items\']/li[16]/div").normalize() == "Sprint 3 47 SP"'
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 4 1 SP"'

    #remove marker
    item_drag_and_drop_plan("//ul[@id=\'backlog-items\']/li[16]", "//ul[@id=\'backlog-items\']/li[1]")
    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 3 48 SP"'

    click_and_wait "link=Sprint"
    click_and_wait "link=Backlog"

    wait_for 'getText("//ul[@id=\'planning-marker-bottom\']/li[1]/div[@class=\'marker-info\']").normalize() == "Sprint 3 48 SP"'
  end
end
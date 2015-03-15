require File.dirname(__FILE__) + "/selenium_helper"

class ArchivedProjectTest < SeleniumTestCase

  def test_not_allowed_actions_in_archived_project
    open_domain
    login

    # archive project
    navigate_to_project_administration
    click '//div[@id="active-projects"]/div/table/tbody/tr[1]/td[6]/form/input'
    sleep 3
    assert /^This will block access to this project for non admin users\.
Are sure you want to do this[\s\S]$/ =~ get_confirmation
    sleep 3
    wait_for 'isElementPresent("flash-ajax")'
    wait_for 'getText("flash-ajax").normalize() == "Project project_1 archived"'

    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'

    click_and_wait "link=Sprint 2"

    click "//li[@id='item-19']/div[1]/span"
    sleep 2
    assert_element_not_present "//li[@id='item-19']/div[1]/span/form/select"

    click "//li[@id='item-19']/span"
    sleep 2
    assert_element_not_present "//li[@id='item-19']/span/form/input[@type='text']"

    expand_item
    wait_for 'isElementPresent("task-5")'
    click "//li[@id='task-5']//span[@class='task-summary highlight']"
    sleep 2
    assert_element_not_present "//li[@id='task-5']//input[@type='text']"

    logout
    login "user_1", "password"

    assert_text_present "You are not currently assigned to any project"

    logout
    login

    # unarchive project
    navigate_to_project_administration

    click '//div[@id="archived-projects"]/div/table/tbody/tr[1]/td[6]/form/input'
    sleep 3
    assert /^This will allow assigned non-admin users to edit this project content\.
Are sure you want to do this[\s\S]$/ =~ get_confirmation
    sleep 3
    wait_for 'isElementPresent("//div[@id=\'active-projects\']")'
    wait_for 'isElementPresent("flash-ajax")'
    wait_for 'getText("flash-ajax").normalize() == "Project project_1 unarchived"'

    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'

    click_and_wait "link=Sprint 2"

    click "//li[@id='item-19']/div[1]/span"
    sleep 2
    assert_element_present "//li[@id='item-19']/div[1]/span/form/select"

    click "//li[@id='item-19']/span"
    sleep 2
    assert_element_present "//li[@id='item-19']/span/form/input[@type='text']"

    expand_item
    wait_for 'isElementPresent("task-5")'
    click "//li[@id='task-5']//span[@class='task-summary highlight']"
    sleep 2
    assert_element_present "//li[@id='task-5']//input[@type='text']"

    logout
  end
end
require File.dirname(__FILE__) + "/selenium_helper"

class ProjectTest < SeleniumTestCase
  def test_add_new_project
    open_domain
    login
    navigate_to_project_administration
    click "link=Add new project"
    fill_form "new_project"
    click "//input[@name='commit' and @value='Create']"

    assert_text_present "first new project"
    assert_text_present "projectcodename"
    assert_text_present "(GMT-06:00) Central Time (US & Canada)"
    assert_text_present "some desc"
  end

  def test_add_new_project_wrong_data
    wrong_data = {
      :project_code_name => "lol asd asd"
    }

    open_domain
    login
    navigate_to_project_administration
    click "link=Add new project"
    fill_form "new_project", wrong_data
    click "//input[@name='commit' and @value='Create']"
    assert_text_present "Name validation failed. Codename can consist of digits, low case alphanumerics, '_' and '-' only."
  end

  def test_save_free_days
    open_domain
    login
    navigate_to_project_administration
    click "link=Add new project"
    fill_form "new_project"

    click "project_free_days_1"
    click "project_free_days_0"
    click "project_free_days_6"
    click "project_free_days_3"
    click "//input[@name='commit' and @value='Create']"

    wait_for 'isTextPresent("first new project")'
    click_edit_project "first new project"

    def assert_free_days_in_project_1
      wait_for 'isElementPresent("project_free_days_1")'
      assert_equal "on", get_value("project_free_days_1")
      assert_equal "off", get_value("project_free_days_2")
      assert_equal "on", get_value("project_free_days_3")
      assert_equal "off", get_value("project_free_days_4")
      assert_equal "off", get_value("project_free_days_5")
      assert_equal "off", get_value("project_free_days_6")
      assert_equal "off", get_value("project_free_days_0")
    end

    assert_free_days_in_project_1

    logout
    login

    navigate_to_project_administration
    click_edit_project "first new project"

    assert_free_days_in_project_1
  end


  def test_edit_values_in_project
    open_domain
    login

    navigate_to_project_administration
    click_edit_project

    click "link=Settings"
    wait_for 'isElementPresent("project[sprint_length]")'
    type "project[sprint_length]", "10"
    type "project[backlog_unit]", "LOL"
    type "project[task_unit]", "parsec"
    type "project[csv_separator]", "."
    click "//div[@id='settings']/form/input"
    select "project_id", "label=Project 1"
    wait_for_page_to_load("5000");
    click_and_wait "link=Backlog"
    wait_for 'getText("//li[@id=\'item-2\']/div[1]").normalize() == "tag_1 (0 parsec) [1 LOL]"'

    click_and_wait "link=Sprint"
    select "filter", "label=All"
    wait_for 'getText("//li[@id=\'item-23\']/div[1]").normalize() == "tag_1 (0 parsec) [1 LOL]"'
    wait_for 'getText("//div[@id=\'main-panel\']/h2[3]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 32 LOL, 8 tasks, 40 parsec"'

    click_and_wait "//a[@class='plan-sprint-link']"
    wait_for 'isElementPresent("//div[@id=\'main-panel\']/h2[1]/table/tbody/tr/td[2]")'
    wait_for 'getText("//div[@id=\'main-panel\']/h2[1]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 32 LOL, 8 tasks, 40 parsec"'
  end

  def test_archive_project
    open_domain
    login

    navigate_to_project_administration
    click '//div[@id="active-projects"]/div/table/tbody/tr[1]/td[6]/form/input'
    sleep 3
    assert /^This will block access to this project for non admin users\.
Are sure you want to do this[\s\S]$/ =~ get_confirmation
    sleep 3

    wait_for 'isElementPresent("flash-ajax")'
    wait_for 'getText("flash-ajax").normalize() == "Project project_1 archived"'
    click '//div[@id="archived-projects"]/div/table/tbody/tr[1]/td[6]/form/input'
    sleep 3
    assert /^This will allow assigned non-admin users to edit this project content\.
Are sure you want to do this[\s\S]$/ =~ get_confirmation
    sleep 3
    wait_for 'isElementPresent("//div[@id=\'active-projects\']")'
    wait_for 'isElementPresent("flash-ajax")'
    wait_for 'getText("flash-ajax").normalize() == "Project project_1 unarchived"'
  end

  def test_edit_project
    open_domain
    login
    navigate_to_project_administration
    click_edit_project

    edited = {
      :project_name => "test_name",
      :project_desc => "some new descryption",
      :project_timezone => "(GMT-09:00) Alaska"
    }

    fill_form "new_project", edited, true

    click "project_free_days_0"
    click "project_free_days_6"
    click "//input[@name='commit' and @value='OK']"

    assert_text_present "Project was successfully updated."
    assert_text_present "test_name"
    assert_text_present "(GMT-09:00) Alaska"
    assert_text_present "some new descryption"
  end

  def test_edit_used_estimates
    open_domain
    login
    
    navigate_to_project_administration
    click_edit_project
    click "link=Settings"
    select "project_estimate_sequence", "label=Linear 0, 1, 2, 3, 4, 5 ..."
    click "//div[@id='settings']/form/input"
    sleep 2
    select "project_id", "label=Project 1"
    wait_for_page_to_load("3000");
    click_and_wait "link=Sprint"
    click "//li[@id='item-19']/div[1]/span"
    select "//div/span/form/select", "label=15"
   
    navigate_to_project_administration
    click_edit_project
    click "link=Settings"
    select "project_estimate_sequence", "label=Square 0, 1, 4, 9, 16, 25 ..."
    click "//div[@id='settings']/form/input"
    sleep 2
    select "project_id", "label=Project 1"
    wait_for_page_to_load("3000");
    click_and_wait "link=Sprint"
    click "//li[@id='item-19']/div[1]/span"
    select "//div/span/form/select", "label=81"

    navigate_to_project_administration
    click_edit_project
    click "link=Settings"
    select "project_estimate_sequence", "label=Fibonnaci 0, 0.5, 1, 2, 3, 5 ..."
    click "//div[@id='settings']/form/input"
    sleep 2
    select "project_id", "label=Project 1"
    wait_for_page_to_load("3000");
    click_and_wait "link=Sprint"
    click "//li[@id='item-19']/div[1]/span"
    select "//div/span/form/select", "label=0.5"
    select "filter", "label=All"
    wait_for 'getText("//div[@id=\'main-panel\']/h2[3]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 29.5 SP, 8 tasks, 40 h"'
  end

  def test_reset_project_settings
    open_domain
    login
    
    navigate_to_project_administration

    click_edit_project
    click "link=Settings"
    select "project_estimate_sequence", "label=Linear 0, 1, 2, 3, 4, 5 ..."
    click "//div[@id='settings']/form/input"
    sleep 2
    select "project_id", "label=Project 1"
    wait_for_page_to_load("3000");
    click_and_wait "link=Sprint"
    click "//li[@id='item-19']/div[1]/span"
    select "//div/span/form/select", "label=15"

    navigate_to_project_administration
    click_edit_project
    click "link=Settings"
    click "reset-to-defaults"
    assert /^Are you sure to reset the settings to default values[\s\S]$/ =~ get_confirmation
    click "link=Close window"
    sleep 2
    select "project_id", "label=Project 1"
    wait_for_page_to_load("3000");
    click_and_wait "link=Sprint"
    click "//li[@id='item-19']/div[1]/span"
    select "//div/span/form/select", "label=0.5"
    wait_for 'getText("//div[@id=\'main-panel\']/h2[3]/table/tbody/tr/td[2]").normalize() == "Total: 10 items, 1 not estimated, 29.5 SP, 8 tasks, 40 h"'
  end

  def test_add_new_users_when_adding_new_project
    open_domain
    login

    navigate_to_project_administration

    click "link=Add new project"
    fill_form "new_project"


    click "assign-members"
    click "project[users_to_assign][team_member][admin_1]"
    click "project[users_to_assign][team_member][user_3]"
    click "assign-scrum-masters"
    click "project[users_to_assign][scrum_master][user_1]"
    click "project[users_to_assign][scrum_master][user_3]"
    click "assign-product-owners"
    click "project[users_to_assign][product_owner][user_2]"
    click "project[users_to_assign][product_owner][user_3]"
    click "//input[@name='commit' and @value='Create']"

    wait_for 'isTextPresent("first new project")'

    click_edit_project "first new project"

    def assert_users_assignments
      wait_for 'isElementPresent("link=Assignments")'
      click "link=Assignments"

      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[2]/td[2]/table/tbody/tr/td").normalize() == "Team Member"'
      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[3]/td[2]/table/tbody/tr/td").normalize() == "Scrum Master"'
      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[4]/td[2]/table/tbody/tr/td").normalize() == "Product Owner"'
      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[5]/td[2]/table/tbody/tr/td[1]").normalize() == "Scrum Master"'
      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[5]/td[2]/table/tbody/tr/td[2]").normalize() == "Product Owner"'
      wait_for 'getText("//table[@id=\'assignments\']/tbody/tr[5]/td[2]/table/tbody/tr/td[3]").normalize() == "Team Member"'
    end

    assert_users_assignments

    logout
    login
    navigate_to_project_administration

    wait_for 'isTextPresent("first new project")'

    click_edit_project "first new project"

    assert_users_assignments
  end
end

require File.dirname(__FILE__) + "/selenium_helper"

class SprintAdministrationTest < SeleniumTestCase
  def test_add_new_sprint
    open_domain
    login
    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'
    click_and_wait "link=Sprints List"
    click "link=New sprint"

    fill_form "new_sprint"
    click "commit"
    assert_text_present "Sprint “testowy” was successfully created."
    logout
    login
    click_and_wait "link=Sprints List"

    assert_text_present "testowy"

    click "delete_sprint_3"
    assert /^Are you sure you want to delete the sprint[\s\S]$/ =~ get_confirmation

    assert_text_present "Sprint 'testowy' was successfully deleted. All sprint items were removed."
    logout
    login
    click_and_wait "link=Sprints List"

    assert_text_not_present "testowy"
  end

  def test_new_sprint_wrong_data
    open_domain
    login
    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'
    click_and_wait "link=Sprints List"
    click "link=New sprint"

    wrong_date = {
      :from_date => "2020-01-04",
      :to_date => "2020-01-01"
    }
    fill_form("new_sprint", wrong_date)
    click "commit"

    assert_text_present "From date has to be before sprint end date"
  end

  def test_edit_sprint
    open_domain
    login
    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'
    click_and_wait "link=Sprints List"
    click '//tr[@id="sprint-2"]//a[@class="edit-sprint-link"]'
    new_data = {
      :name => "New Sprint 4"
    }
    fill_form "new_sprint", new_data, true
    click "commit"

    assert_text_present "New Sprint 4"
  end

  def test_check_days_in_sprint
    def type_and_check_dates
      wait_for 'isElementPresent("//a[@class=\'dp-choose-date\']")'
      type "sprint_from_date", "2009-09-10"
      type "sprint_to_date", "2009-09-21"
      type "sprint_name", "test"
      wait_for 'isTextPresent("Sprint length in days: 12 (excluding free days: 8)")'
      type "sprint_from_date", "2009-09-10"
      type "sprint_to_date", "2009-09-10"
      wait_for 'isTextPresent("Sprint length in days: 1 (excluding free days: 1)")'
      type "sprint_from_date", "2009-09-10"
      type "sprint_to_date", "2009-09-06"
      wait_for 'isTextPresent("Sprint length in days: 0 (excluding free days: 0)")'
      type "sprint_from_date", "2009-09-25"
      type "sprint_to_date", "2009-10-19"
      wait_for 'isTextPresent("Sprint length in days: 25 (excluding free days: 17)")'
      type "sprint_from_date", "2012-02-28"
      type "sprint_to_date", "2012-02-29"
      wait_for 'isTextPresent("Sprint length in days: 2 (excluding free days: 2)")'
      type "sprint_from_date", "2009-12-31"
      type "sprint_to_date", "2010-01-02"
      wait_for 'isTextPresent("Sprint length in days: 3 (excluding free days: 2)")'
      type "sprint_from_date", "2009-12-05"
      type "sprint_to_date", "2009-12-06"
      wait_for 'isTextPresent("Sprint length in days: 2 (excluding free days: 0)")'
    end

    open_domain
    login
    select "project_id", "label=Project 1"
    wait_for 'isElementPresent("link=Sprints List")'
    click_and_wait "link=Sprints List"
    wait_for 'isElementPresent("link=New sprint")'
    click "link=Edit"
    type_and_check_dates
    click_and_wait "link=Sprints List"
    wait_for 'isElementPresent("link=New sprint")'
    click "link=New sprint"
    type_and_check_dates
  end
end
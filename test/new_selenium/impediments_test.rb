require File.dirname(__FILE__) + "/selenium_helper"

class ImpedimentsTest < SeleniumTestCase
  def test_add_new_impediments_and_comment_it
    open_sprint_page
    login

    expand_impediments_container
    click "link=New impediment"

    type "impediment_summary", "super impediment"
    type "impediment_description", "some description"
    click_create_impediment

    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'

    wait_for 'isElementPresent("link=New impediment")'
    click "link=New impediment"
    wait_for 'isElementPresent("impediment_summary")'
    sleep 2
    type "impediment_summary", "another impediment"
    type "impediment_description", "another descripition"
    click_create_impediment
    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'
    sleep 1
    
    # close impediment with comment
    click "//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']"
    click "//ul[@id='impediments-list']//li[@class='tab']/a"
    type "comment", "comment which close it"
    click "//a[@class='close-impediment']"
    wait_for 'isElementPresent("//li[@id=\'impediment-1\']//span[@class=\'comment-text\']")'
    wait_for 'getText("//li[@id=\'impediment-1\']//span[@class=\'comment-text\']").normalize() == "comment which close it"'
    sleep 1

    # add new comment
    wait_for 'isElementPresent("//textarea[@id=\'comment\']")'
    type "//textarea[@id='comment']", "comment super something"
    click "//a[@class='post-impediment-comment']"
    sleep 1

    # open with comment
    type "comment", "open once again"
    click "//a[@class='reopen-impediment']"
    wait_for 'isElementPresent("//li[@id=\'impediment-1\']//span[@class=\'comment-text\']")'
    wait_for 'getText("//li[@id=\'impediment-1\']//li[1]/span[@class=\'comment-text\']").normalize() == "open once again"'
    wait_for 'getText("//li[@id=\'impediment-1\']//li[2]/span[@class=\'comment-text\']").normalize() == "comment super something"'
    wait_for 'getText("//li[@id=\'impediment-1\']//li[3]/span[@class=\'comment-text\']").normalize() == "comment which close it"'
    sleep 1

    # Delete impediment
    click "//img[@class='trash delete-impediment']"
    assert /^Are you sure you want to delete impediment 'super impediment' [\s\S]$/ =~ get_confirmation

    wait_for 'isElementPresent("impediment-1") == false'
    assert_element_not_present "impediment-1"
  end

  def test_edit_impediment
    open_sprint_page
    login

    expand_impediments_container
    click "link=New impediment"

    type "impediment_summary", "super impediment"
    type "impediment_description", "some description"
    click_create_impediment

    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'

    click "//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']"
    click "//li[@id='impediment-1']//span"
    wait_for 'isElementPresent("//li[@id=\'impediment-1\']//span//input[@type=\'text\']")'
    type "//li[@id='impediment-1']//span//input[@type='text']", 'edited impediment'
    click '//button[@type=\'submit\']'
    wait_for 'isTextPresent("edited impediment")'

    logout

    open_sprint_page
    login
    expand_impediments_container
    wait_for 'isTextPresent("edited impediment")'
  end
end

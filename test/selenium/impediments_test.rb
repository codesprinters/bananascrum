require File.dirname(__FILE__) + "/selenium_helper"

class ImpedimentsTest < SeleniumTestCase
   def test_add_new_impediments_and_comment_it
    open_sprint_page
    login

    click '//div[@id="impediments_container"]/h2/a/div'
    click "link=New impediment"

    type "impediment_summary", "super impediment"
    type "impediment_description", "some description"
    click "//input[@value='Create']"

    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'

    wait_for 'isElementPresent("link=New impediment")'
    click "link=New impediment"
    wait_for 'isElementPresent("impediment_summary")'
    sleep 2
    type "impediment_summary", "another impediment"
    type "impediment_description", "another descripition"
    click "//input[@value='Create']"

    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'

    # close impediment with comment
    click "//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']"
    type "comment", "comment which close it"
    click "//input[@name='commit' and @value='OK']"
    wait_for 'isElementPresent("//li[@id=\'impediment-1\']/div[2]/ul/li/div/p")'
    wait_for 'getText("//li[@id=\'impediment-1\']/div[2]/ul/li/div/p").normalize() == "comment which close it"'

    # add new comment
    click "link=Add new comment"
    wait_for 'isElementPresent("//textarea[@id=\'comment\']")'
    type "//textarea[@id='comment']", "comment super something"
    click "//li[@id='impediment-1']/div[2]/div[4]/form/p[2]/input"

    # open with comment
    type "comment", "open once again"
    click "//input[@name='commit' and @value='OK']"
    wait_for 'isElementPresent("//li[@id=\'impediment-1\']/div[2]/ul/li[3]/div/p")'
    wait_for 'getText("//li[@id=\'impediment-1\']/div[2]/ul/li[3]/div/p").normalize() == "open once again"'
    wait_for 'getText("//li[@id=\'impediment-1\']/div[2]/ul/li[2]/div/p").normalize() == "comment super something"'
    wait_for 'getText("//li[@id=\'impediment-1\']/div[2]/ul/li[1]/div/p").normalize() == "comment which close it"'

    # Delete impediment
    click "//div/div[2]/div[4]/div/ul[2]/li/div/img"
    assert /^Are you sure you want to delete impediment 'super impediment' [\s\S]$/ =~ get_confirmation

    wait_for 'isElementPresent("impediment-1") == false'
    assert_element_not_present "impediment-1"
  end

  def test_edit_impediment
    open_sprint_page
    login

    click '//div[@id="impediments_container"]/h2/a/div'
    click "link=New impediment"

    type "impediment_summary", "super impediment"
    type "impediment_description", "some description"
    click "commit"

    wait_for 'isElementPresent("//ul[@id=\'impediments-list\']//div[@class=\'icon expand-icon expand\']")'

    click '//li[@class="impediment expandable collapsed"]/span'
    wait_for 'isElementPresent("//span/form/input[@type=\'text\']")'
    type '//span/form/input[@type=\'text\']', 'edited impediment'
    click '//button[@type=\'submit\']'
    wait_for 'isTextPresent("edited impediment")'

    logout

    open_sprint_page
    login
    click '//div[@id="impediments_container"]/h2/a/div'
    wait_for 'isTextPresent("edited impediment")'
  end
end

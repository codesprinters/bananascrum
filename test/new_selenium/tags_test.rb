require File.dirname(__FILE__) + "/selenium_helper"

class TagsTest < SeleniumTestCase
  def test_manage_tags
    open_backlog_page
    login

    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"

    click "//li[@id='tag-2']//span[@class='tag-name']"

    wait_for 'isElementPresent("//form[@class=\'editor-field edit-tag-form\']//input[@type=\'text\']")'
    type "//form[@class=\'editor-field edit-tag-form\']//input[@type=\'text\']", "super new tag"
    click "//form[@class=\'editor-field edit-tag-form\']//button[@type=\'submit\']"
    wait_for 'getText("//li[@id=\'tag-2\']//span[@class=\'tag-name\']") == "super new tag"'

    click "//li[@id='tag-2']//a[@class='destroy']"
    assert_text_not_present "super new tag"
  end
  
  def test_add_new_tag
    open_backlog_page
    login

    click "//li[@id='item-3']//img[@alt='Assign tag']"
    wait_for 'isElementPresent("tag")'
    sleep 3
    type "tag", "new test tag"
    sleep 1
    click "//input[@name='commit' and @value='OK']"
    wait_for 'isElementPresent("//li[@id=\'item-3\']//span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-3\']//span[@class=\'tag-name\']") == "new test tag"'
    click "//li[@id='item-4']//img[@alt='Assign tag']"
    wait_for 'isElementPresent("tag")'
    sleep 1
    type "tag", "another tag"
    sleep 1
    click "//input[@name='commit' and @value='OK']"
    wait_for 'isElementPresent("//li[@id=\'item-4\']//span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-4\']//span[@class=\'tag-name\']") == "another tag"'
    click "//li[@id='item-4']//img[@alt='Assign tag']"
    wait_for 'isElementPresent("tag")'
    sleep 2
    type "tag", "lol tag"
    sleep 1
    click "//input[@name='commit' and @value='OK']"
    wait_for 'isElementPresent("//li[@id=\'item-4\']//li[2]//span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-4\']//li[2]//span[@class=\'tag-name\']") == "lol tag"'

    open_backlog_page

    wait_for 'isElementPresent("//li[@id=\'item-4\']//li[2]/span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-4\']//li[2]/span[@class=\'tag-name\']") == "lol tag"'
    wait_for 'isElementPresent("//li[@id=\'item-4\']//span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-4\']//span[@class=\'tag-name\']") == "another tag"'
    wait_for 'isElementPresent("//li[@id=\'item-3\']//span[@class=\'tag-name\']")'
    wait_for 'getText("//li[@id=\'item-3\']//span[@class=\'tag-name\']") == "new test tag"'

    click "//li[@id='tag-2']/span[1]"
    assert_visible("//li[@id='item-9']")
    assert_not_visible("//li[@id='item-8']")
  end

  def test_add_item_with_tags
    open_planning_page
    login

    click "link=New backlog item"
    type "item_user_story", "test"
    select "item_estimate", "label=1"
    type "item_description", "test"
    click "tags_1"
    click "tags_2"
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("item-29")'
    wait_for 'getText("//li[@id=\'item-29\']//li[1]/span") == "tag_1"'
    wait_for 'getText("//li[@id=\'item-29\']//li[2]/span") == "tag_2"'
  end

  def test_add_tag_from_new_item_form
    open_backlog_page
    login

    click "link=Add item"
    type "item_user_story", "test"
    select "item_estimate", "label=1"
    type "item_description", "testdesc"
    click "tags_1"
    type "new_item_tag", "testtag"
    key_down "new_item_tag", "\\13" # send key ENTER
    sleep 1
    type "new_item_tag", "testtag2"
    key_down "new_item_tag", "\\13" # send key ENTER
    sleep 1
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("item-29")'
    wait_for 'getText("//li[@id=\'item-29\']//li[1]/span") == "tag_1"'
    wait_for 'getText("//li[@id=\'item-29\']//li[2]/span") == "testtag"'
    wait_for 'getText("//li[@id=\'item-29\']//li[3]/span") == "testtag2"'
  end


  def test_tag_description
    open_backlog_page
    login

    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"

    click "//li[@id='tag-2']//a/img[@alt='Edit']"
    wait_for 'isElementPresent("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]//input")'
    type "//li[@id='tag-2']//span[contains(@class, \'tag-description\')]//input", "some tag description"
    click "//li[@id='tag-2']//div[@class='submit-cancel-container']//button[@type='submit']"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some tag description"'
    open_backlog_page
    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some tag description"'
    open_sprint_page
    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some tag description"'
    assert_equal "some tag description", get_attribute('//li[@id=\'item-19\']//li[1]/span@title')
    click "//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]"
    type "//li[@id='tag-2']//span[contains(@class, \'tag-description\')]//input", "some edited tag description"
    click "//li[@id='tag-2']//div[@class='submit-cancel-container']//button[@type='submit']"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some edited tag description"'
    open_backlog_page
    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some edited tag description"'
    open_sprint_page
    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"
    wait_for 'getText("//li[@id=\'tag-2\']//span[contains(@class, \'tag-description\')]") == "some edited tag description"'
    assert_equal "some edited tag description", get_attribute('//li[@id=\'item-19\']//li[1]/span@title')
  end

  def test_add_tag_from_manage_tags
    open_backlog_page
    login

    click "//div[@id='tag-info-box']//a/div"
    click "manage-tags-link"
    wait_for "isElementPresent('tag')"
    type "tag", "justanewtag"
    click "//input[@value='OK']"
    wait_for "isTextPresent('justanewtag')"

    click "link=Add item"
    type "item_user_story", "test"
    select "item_estimate", "label=1"
    type "item_description", "testdesc"
    click "tags_1" #Select new tag from tags - it should be first on the tags list
    click "//input[@name='commit' and @value='Create']"
    wait_for 'isElementPresent("item-29")'
    wait_for 'getText("//li[@id=\'item-29\']//li/span") == "justanewtag"'
  end

end
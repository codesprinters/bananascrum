require File.dirname(__FILE__) + "/selenium_helper"

class CommentsTest < SeleniumTestCase
  def test_add_comments_on_sprint_page
    open_sprint_page
    login

#    click_and_wait "link=Project 1"
#    click_and_wait "link=Sprint"
    expand_item
    click "link=Add comment"
    type "comment_text", "asdasdasd"
    click "commit"

    assert_text_present "asdasdasd"
    type "comment_text", "qweqweqwe"
    click "commit"
    assert_text_present "qweqweqwe"
    click "link=Close window"
    assert_text_present "Add comment [2]"
  end

  def test_add_comments_on_backlog_page
    open_backlog_page
    login

    expand_item
    click "link=Add comment"
    type "comment_text", "some comment"
    click "//input[@name='commit' and @value='Post comment']"
    assert_text_present "some comment"
    type "comment_text", "another comment"
    click "//input[@name='commit' and @value='Post comment']"
    assert_text_present "another comment"
    click "link=Close window"
    assert_text_present "Add comment [2]"
  end
end


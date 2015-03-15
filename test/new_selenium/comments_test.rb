require File.dirname(__FILE__) + "/selenium_helper"

class CommentsTest < SeleniumTestCase
  def test_add_comments_on_sprint_page
    open_sprint_page
    login

    expand_item
    click "//li[contains(@class, 'tab-comments')]//a"
    type "comment_text", "first comment"
    click "//input[@value='Post comment']"
    assert_text_present "first comment"
    type "comment_text", "second comment"
    click "//input[@value='Post comment']"
    assert_text_present "second comment"
    assert_text_present "Comments (2)"
  end

  def test_add_comments_on_backlog_page
    open_backlog_page
    login

    expand_item
    click "//li[contains(@class, 'tab-comments')]//a"
    type "comment_text", "some comment"
    click "//input[@value='Post comment']"
    assert_text_present "some comment"
    type "comment_text", "another comment"
    click "//input[@value='Post comment']"
    assert_text_present "another comment"
    assert_text_present "Comments (2)"
  end
end


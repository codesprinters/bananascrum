require File.dirname(__FILE__) + "/selenium_helper"

class LoginTest < SeleniumTestCase
  def test_correct_login_admin
    open_domain
    login
    assert_text_present "Logged in successfully"
    assert_text_present "Logged as:"
    logout
  end

  def test_correct_login_user_not_admin
    open_domain
    login "user_1", "password"
    assert_text_present "Logged in successfully"
    assert_text_present "Logged as:"
    logout
  end
  
  def test_wrong_username
    open_domain
    login "notexistedlogin", "password"
    assert_text_present  "Login failed"
    assert_text_not_present "Logged as:"
  end

  def test_wrong_password
    open_domain
    login "admin_1", "12qw12"
    assert_text_present  "Login failed"
    assert_text_not_present "Logged as:"
  end

  def test_wrong_username_and_password
    open_domain
    login "notexistedlogin", "notexistedpassword"
    assert_text_present "Login failed"
    assert_text_not_present "Logged as:"
  end

  def test_password_remember
    open_domain
    password_remember "admin_1"
  end
end
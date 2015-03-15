require File.dirname(__FILE__) + "/selenium_helper"

class LoginTest < SeleniumTestCase


  def test_correct_login_admin
    open_domain
    login
    assert_correct_login
    logout
  end

  def test_correct_login_user_not_admin
    open_domain
    login "user_4", "password"
    assert_correct_login
    logout
  end
  
  def test_wrong_username
    open_domain
    login "notexistedlogin", "password"
    assert_login_failed
  end

  def test_wrong_password
    open_domain
    login "admin_2", "12qw12"
    assert_login_failed
  end

  def test_wrong_username_and_password
    open_domain
    login "notexistedlogin", "notexistedpassword"
    assert_login_failed
  end

  def test_password_remember
    open_domain
    password_remember "admin_2"
  end
end
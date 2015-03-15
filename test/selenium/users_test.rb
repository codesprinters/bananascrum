require File.dirname(__FILE__) + "/selenium_helper"

class UsersTest < SeleniumTestCase
  def test_add_user
    open_domain
    login
    navigate_to_users_administration
    click_new_user
    fill_form "new_user"
    click "form_submit"

    assert_text_present "User “new_user” was successfully created."
    assert_text_present "new_user"
    assert_text_present "Tester"
    assert_text_present "Testowski"
    assert_text_present "Never"

    click '//a[text()="new_user"]/../../../td[8]/form/a'

    assert /^Are you sure you want to delete user[\s\S]$/ =~ get_confirmation
  end

  def test_add_user_wrong_datas
    open_domain
    login
    navigate_to_users_administration
    
    click_new_user
    wrong_data = {
      :email => "asdasdasdasd",
      :login => "admin_1"
    }

    fill_form "new_user", wrong_data
    click "form_submit"

    assert_text_present "Email address is invalid"
    assert_text_present "Login has already been taken"
  end

  def test_add_user_empty_datas
    open_domain
    login
    navigate_to_users_administration
    click_new_user
    click "form_submit"

    assert_text_present "Last name can't be blank"
    assert_text_present "Email address can't be blank"
    assert_text_present "Email address is invalid"
    assert_text_present "Login can't be blank"
    assert_text_present "Login is too short (minimum is 3 characters)"
    assert_text_present "First name can't be blank"
  end

  def test_assign_user_to_project
    open_domain
    login

    navigate_to_project_administration
    click_edit_project

    select "user_id", "label=admin_1"
    click "//input[@name='commit' and @value='Assign']"
    assert_text_present "User admin_1 assigned to project project_1 as Team Member."
    assert_equal "admin_1", get_text("//table[@id='assignments']/tbody/tr[2]/td[1]")

    click "//img[@alt='Remove this role']"
    sleep 5
    assert /^Are you sure you want to remove this role[\s\S]$/ =~ get_confirmation
    sleep 3
    assert_text_present "User admin_1 was unassigned from project_1 project as Team Member."
  end

 def test_add_admin_permission_to_user
    open_domain
    login
    navigate_to_users_administration
    DomainChecks.disable do
      @user = User.find_by_login("user_2")
    end

    click "//tr[@id='user-row-#{@user.id.to_s}']//input[@name='user_admin']"

    wait_for 'isElementPresent("flash-ajax")'
    wait_for 'getText("flash-ajax") == "Admin rights have been granted to user user_2"'
    logout
    login "user_2"
    assert_element_present "link=Admin"
  end
  
 def test_block_user
    open_domain
    login
    navigate_to_users_administration

    click_block_user
    wait_for 'isElementPresent(\'//div[@id="blocked-users"]//a\')'
    wait_for 'getText(\'//div[@id="blocked-users"]//a\') == "user_3"'
    logout
    login "user_3"

    assert_text_present "Your account has been blocked. Please contact your domain administrator"

    login
    navigate_to_users_administration
    click_unblock_user
    wait_for 'isElementPresent(\'//div[@id="active-users"]//tr[6]//a\')'
    wait_for 'getText(\'//div[@id="active-users"]//tr[6]//a\') == "user_3"'
    logout

    login "user_3"
    assert_text_present "Logged in successfully"
  end

  def test_password_reset
    open_domain
    login
    navigate_to_users_administration
    click "link=user_1"

    click "reset-password"
    sleep 2
    assert /^Are sure you want to do this[\s\S]$/ =~ get_confirmation
    sleep 4

    assert_text_present("Password resetted and sent over to user")
  end

  def test_change_user_password
    open_domain
    login
    click_and_wait "link=John Doe"
    click_and_wait "link=Change password"
    wait_for 'isElementPresent("user_user_password")'
    type "user_user_password", "qw12qw"
    type "user_user_password_confirmation", "qw12qw"
    click_and_wait "user_submit"

    logout
    login("admin_1", "qw12qw")
  end

  def test_change_user_password_to_short
    open_domain
    login
    click_and_wait "link=John Doe"
    click_and_wait "link=Change password"
    wait_for 'isElementPresent("user_user_password")'
    type "user_user_password", "qw12"
    type "user_user_password_confirmation", "qw12"
    click_and_wait "user_submit"

    wait_for 'isElementPresent("flash-error")'
    wait_for 'getText("flash-error").normalize() == "Password update failed."'
  end

  def test_change_user_password_different
    open_domain
    login
    click_and_wait "link=John Doe"
    click_and_wait "link=Change password"
    wait_for 'isElementPresent("user_user_password")'
    type "user_user_password", "qw12qw"
    type "user_user_password_confirmation", "qw12qw12"
    click_and_wait "user_submit"

    wait_for 'isElementPresent("flash-error")'
    wait_for 'getText("flash-error").normalize() == "Password update failed."'
  end


  def test_edit_user_profile
    open_domain
    login "user_1"
    click_and_wait "link=John Doe"
    
    fill_form "edit_user"
    click_and_wait "user_submit"

    wait_for 'getValue("user_first_name").normalize() == "test"'
    wait_for 'getValue("user_last_name").normalize() == "testowy"'
    wait_for 'isElementPresent("link=test testowy")'
  end


  def test_edit_admin_profile
    open_domain
    login
    click_and_wait "link=John Doe"
    
    fill_form "edit_user"
    type "user_login", "new_login"
    click_and_wait "user_submit"

    wait_for 'getValue("user_first_name").normalize() == "test"'
    wait_for 'getValue("user_last_name").normalize() == "testowy"'
    wait_for 'isElementPresent("link=test testowy")'

    logout
    login "new_login"
    wait_for 'isElementPresent("link=test testowy")'
  end
end

require File.dirname(__FILE__) + "/selenium_helper"

class RegisterFirstDomain < SeleniumTestCase
  def test_register_with_correct_data
    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license"
    click_and_wait "commit"
    wait_for 'isElementPresent("//div[@id=\'main-panel\']/form/fieldset/h2")'
    wait_for 'getText("//div[@id=\'main-panel\']/form/fieldset/h2") == "Admin account information"'
  end

  def test_register_with_wrong_entity_name
    wrong_company_name = {
      :license_entity_name => "CodeSprinters"
    }

    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", wrong_company_name
    click_and_wait "commit"
    assert_text_present "Key is invalid"
  end

  def test_register_with_wrong_licence_key
    wrong_license_key_first_line = {
      :license_key => "===== LICENSE BEGIN =====\nQ49kZSBTcHJpbnRlcnM=:\naU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyF\nyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5\ncmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=\n===== LICENSE END ======="
    }

    wrong_license_key_second_line = {
      :license_key => "===== LICENSE BEGIN =====\nQ29kZSBTcHJpbnRlcnM=:\naU+O4jSqR3xTdrXJDOyJEsKlkeaddscdzDeyav4R0JbyO8hoSM35Cg/7lUyF\nyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5\ncmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=\n===== LICENSE END ======="
    }

    wrong_license_key_first_line_without_header = {
      :license_key => "Q29kZSBTdHJpbnRlcnM=:\naU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyF\nyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5\ncmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34="
    }

    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", wrong_license_key_first_line
    click_and_wait "commit"
    assert_text_present "Key is invalid"

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", wrong_license_key_second_line
    click_and_wait "commit"
    assert_text_present "Key is invalid"

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", wrong_license_key_first_line_without_header
    click_and_wait "commit"
    assert_text_present "Key is invalid"
  end

  def test_register_company_empty_licence_key
    empty_license_key = {
      :license_key => ""
    }

    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", empty_license_key
    click_and_wait "commit"
    assert_text_present "Key can't be blank"
  end

  def test_register_company_empty_entity_name
    empty_entity_name = {
      :license_entity_name => ""
    }

    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license", empty_entity_name
    click_and_wait "commit"

    assert_text_present "Key is invalid"
    assert_text_present "Entity name can't be blank"
  end

 
  def test_add_first_admin_correct
    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license"
    click_and_wait "commit"

    fill_form "first_admin"
    click_and_wait "commit"
    login "admin", "qw12qw12"
    assert_text_present "Logged in successfully"
    assert_text_present "Logged as:"
    logout

    open_domain
    login "admin", "qw12qw12"
    assert_text_present "Logged in successfully"
    assert_text_present "Logged as:"
  end

  def test_add_first_admin_wrong_email
    wrong_email = {
      :email => "asdasdasdads.pl"
    }
    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license"
    click_and_wait "commit"

    fill_form "first_admin", wrong_email
    click_and_wait "commit"
    assert_text_present "Email address is invalid"
  end

  def test_add_first_admin_empty_data
    empty_data = {
      :email => "",
      :login => "",
      :first_name => "",
      :last_name => "",
      :password => "",
    }
    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license"
    click_and_wait "commit"

    fill_form "first_admin", empty_data
    click_and_wait "commit"
    assert_text_present "Email address can't be blank"
    assert_text_present "Login can't be blank"
    assert_text_present "First name can't be blan"
    assert_text_present "User password can't be blank"
    assert_text_present "Last name can't be blank"

    open_domain
    wait_for 'getText("//div[@id=\'main-panel\']/form/fieldset/h2") == "Admin account information"'
  end

  def test_add_first_admin_wrong_password
    wrong_password = {
      :password => "qw12qw",
    }
    setup_new_domain

    open_domain

    wait_for 'isElementPresent("license_entity_name")'
    fill_form "first_domain_license"
    click_and_wait "commit"

    fill_form "first_admin", wrong_password
    click_and_wait "commit"
    assert_text_present "User password doesn't match confirmation"
  end
end
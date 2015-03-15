dir = File.dirname(__FILE__)
require dir + "/../test_helper"
require 'selenium'
require 'polonium'

class SeleniumTestCase < ActionController::IntegrationTest 
  include Polonium::SeleniumDsl

  delegate :select, :to => :selenium_driver

  SCREENSHOT_DIR = "#{RAILS_ROOT}/screenshots"

  def setup
    super
    @selenium_driver = configuration.driver

    # Restore database and reset session state
    dumper = MysqlDumper.new(ActiveRecord::Base.configurations[RAILS_ENV])
    dumper.restore("#{RAILS_ROOT}/db/populate.dump")
    open "/reset"
  end

  def teardown
    @selenium_driver.stop if stop_driver?
    super
  end

  # Generate name of a screenshot file based on backtrace
  def screenshot_on_exception(message, backtrace)
    regexp = /test\/selenium\/([^.]+)_test\.rb:[0-9]+:in `test_([^']+)'/
    first_match = backtrace.map {|row| row.match(regexp) }.compact.first
    return if first_match.nil?

    begin
      make_screenshot first_match[1] + "_" + first_match[2]
    rescue SeleniumCommandError
      # Continue if we cannot make a screenshot
    end
  end

  def add_failure_with_screenshot(message, backtrace)
    screenshot_on_exception(message, backtrace)
    add_failure_without_screenshot(message, backtrace)
  end

  def add_error_with_screenshot(e)
    screenshot_on_exception(e.message, e.backtrace)
    add_error_without_screenshot(e)
  end

  # Make a screenshot after every failed test
  alias_method_chain :add_failure, :screenshot
  alias_method_chain :add_error, :screenshot

  def default_test
    # Method empty on purpose to avoid errors from test runner
  end


  # Helper methods that are shared between all tests
  def setup_new_domain
    Domain.delete_all
    Domain.create_default
  end

  def submit
    click_and_wait "commit"
    assert_text_present "Banana Scrum"
  end

  def login(login = "admin_2", password = "password")
    type "login", "#{login}"
    type "password", "#{password}"
    submit
  end

  def logout
    click_and_wait "link=Logout"
    assert_text_present "You have been logged out"
    assert_text_not_present "Logged as:"
  end

  def password_remember(login = "admin_1")
    click_and_wait "forgot-password"
    type "login", "#{login}"
    submit
    assert_text_present "Activation link to reset password sent to email."
  end

  def open_domain(url="/")
    open "#{url}"
  end


  def fill_form(form_name, additional_params = nil, filtered = nil)

    forms = {


      :first_domain_license => {
        :license_entity_name => { :type => "type", :name => "license[entity_name]", :value => "Code Sprinters" },
        :license_key => { :type => "type", :name => "license[key]", :value => "===== LICENSE BEGIN =====\nQ29kZSBTcHJpbnRlcnM=:\naU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyFyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5cmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=\n===== LICENSE END ======="
        }
      },

      :first_admin => {
        :first_name => { :type => "type", :name => "admin_first_name", :value => "Admin"},
        :last_name => { :type => "type", :name => "admin_last_name", :value => "Adminowski"},
        :login => { :type => "type", :name=>"admin_login", :value => "admin"},
        :password => { :type => "type", :name=>"admin_user_password", :value => "qw12qw12"},
        :password_confirmation => { :type => "type", :name=>"admin_user_password_confirmation", :value => "qw12qw12"},
        :email => { :type => "type", :name=>"admin_email_address", :value => "wzolnowski@codesprinters.com"}
      },

      :new_project => {
        :project_name => {:type => "type", :name => "project[presentation_name]", :value => "first new project"},
        :project_code_name => {:type => "type", :name => "project[name]", :value => "projectcodename"},
        :project_desc => {:type => "type", :name => "project[description]", :value => "some desc"},
        :project_timezone => {:type => "select", :name => "project[time_zone]", :value => "(GMT-06:00) Central Time (US & Canada)"}
      },

      :new_user => {
        :login => {:type => "type", :name => "form[login]", :value => "new_user"},
        :first_name => {:type => "type", :name => "form[first_name]", :value => "Tester"},
        :last_name => {:type => "type", :name => "form[last_name]", :value => "Testowski"},
        :email => {:type => "type", :name => "form[email_address]", :value => "wzolnowski@codesprinters.com"},
        :user_project_1 => {:type => "click", :name => "form[to_assign]"},
        :user_project_2 => {:type => "click", :name => "form[projects_to_assign][0]"},
        :user_role => {:type => "click", :name => "form[roles_to_assign][1]"}
      },

      :new_sprint => {
        :nr => {:type => "type", :name => "sprint_sequence_number", :value => "3"},
        :name => {:type => "type", :name => "sprint_name", :value => "testowy"},
        :goals => {:type => "type", :name => "sprint_goals", :value => "bla bla bla"},
        :from_date => {:type => "type", :name => "sprint_from_date", :value => "2020-07-01"},
        :to_date => {:type => "type", :name => "sprint_to_date", :value => "2020-07-20"},

      },

      :new_item => {
        :user_story => {:type => "type", :name => "item_user_story", :value => "some new user story"},
        :description => {:type => "type", :name => "item_description", :value => "some description"},
        :estimate => {:type => "select", :name => "item_estimate", :value => "2"}
      },

      :edit_user => {
        :first_name => {:type => "type", :name => "user[first_name]", :value => "test"},
        :last_name => {:type => "type", :name => "user[last_name]", :value => "testowy"},
        :email =>{:type => "type", :name => "user[email_address]", :value => "mail@me.pl"}
      }

    }
    # select option

    fields = forms[form_name.to_sym]

    # when we need fill only specific fields we can use 'filtered' option, and type in additional_params only needed fields
    if filtered == true
      result = {}
      additional_params.each do |k, v|
        if fields.has_key?(k)
          result[k] = fields[k]
          result[k][:value] = v
        end
      end
      fields = result
    end

    # iteration on hash with fields which change values typed in additional_params
    if additional_params
      additional_params.each do |k, v|
        if fields.has_key?(k)
          fields[k][:value] = v
        end
      end
    end

    # iteration which fill all fields from hash 'fields'
    fields.each do |k, v|
      case v[:type]
      when "type"
        type v[:name], v[:value]
      when "select"
        select v[:name], "label=#{v[:value]}"
      when "click"
        if v[:value]
          v[:name] = v[:value]
        end
        click v[:name]
      when "captcha"
        type @captcha[v[:name]], v[:value]
      end
    end

  end

  def navigate_to_project_administration
    click_and_wait "link=Admin"
    click "link=Projects"
    wait_for 'isElementPresent("//div[@id=\'active-projects\']")'
  end

  def navigate_to_users_administration
    click_and_wait "link=Admin"
    click "link=Users"
    wait_for 'isElementPresent("//div[@id=\'active-users\']")'
  end

  def click_new_user
    click "link=Add new user"
    wait_for 'isElementPresent("form[login]")'
  end

  def wait_for(script)
    wait_for_condition "selenium.#{script}", 20000
  rescue SeleniumCommandError => e
    new_exception = e.exception(e.message + " Script: " + script)
    raise new_exception
  end

  def make_screenshot(name)
    return if name.nil?
    FileUtils.mkdir_p SCREENSHOT_DIR
    window_focus
    window_maximize
    capture_entire_page_screenshot "#{SCREENSHOT_DIR}/#{name}.png"
  end

  def assert_correct_login
    assert_text_present "Logged in successfully"
  end

  def assert_login_failed
    assert_text_present  "Login failed"
  end

  def password_remember(login = "admin_1")
    click_and_wait "forgot-password"
    type "login", "#{login}"
    submit
    assert_text_present "Activation link to reset password sent to email."
  end

  def click_new_user
    click "link=Add new user"
    wait_for 'isElementPresent("form[login]")'
  end

  # ==========================================================================
  # Assertions:

  def texts_present_assertion(*texts)
    texts.each do |text|
      assert_text_present text
    end
  end

  def expand_item(user_story = nil)
    if user_story
      DomainChecks.disable do
        @item = Item.find_by_user_story(user_story)
      end
      item_id = @item.id
      path = "//li[@id=\'item-#{item_id}\']"
    else
      path = ""
    end

    item_path = "//div[contains(@class, \'expandable-list\')]"+ path +"//div[@class=\'icon expand-icon expand\']"
    click item_path
  end

  def edit_task_summary(task_summary, new_value)
    DomainChecks.disable do
      @task = Task.find_by_summary(task_summary)
    end
    task_id = @task.id
    
    task_path = "//li[@id='task-#{task_id}']"
    click task_path + "//div[contains(@class, 'task-summary')]"
    type "//form[@class='editor-field']//input[@type='text']", new_value
    click "//button[@type='submit']"
  end

  def edit_task_estimate(task_summary, new_value)
    DomainChecks.disable do
      @task = Task.find_by_summary(task_summary)
    end
    task_id = @task.id
    
    task_path = "//li[@id='task-#{task_id}']"
    click task_path + "//span[contains(@class, 'task-estimate')]"
    type "//form[@class='editor-field']//input[@type='text']", new_value
    click "//button[@type='submit']"
    sleep 2
  end

  def assert_task(task_id, summary, estimate, users)
    wait_for "getText('#{task_id}').normalize() == '#{summary} (#{estimate}h) [#{users}]'"
  end

  def click_edit_project(project= "Project 1")
    DomainChecks.disable do
      @project = Project.find_by_presentation_name(project)
    end
    click "//div[@id='active-projects']//tr[@id='project-row-#{@project.id.to_s}']//a[@class='edit-project-link']"
  end


  def click_block_user(user="user_3")
    DomainChecks.disable do
      @user = User.find_by_login(user)
    end
    click "//div[@id='active-users']//tr[@id='user-row-#{@user.id.to_s}']//a[@class='block-user block']"
  end

  def click_unblock_user(user="user_3")
    DomainChecks.disable do
      @user = User.find_by_login(user)
    end
    click "//div[@id='blocked-users']//tr[@id='user-row-#{@user.id.to_s}']//a[@class='block-user unblock']"
  end

  def open_sprint_page(project="Project 1", sprint="Sprint 2")
    DomainChecks.disable do
      @project = Project.find_by_presentation_name(project)
      @sprint = Sprint.find_by_name(sprint)
    end
    path = project_sprint_path(@project.name, @sprint.id)
    open_domain path
  end

  def open_backlog_page(project="Project 1")
    DomainChecks.disable do
      @project = Project.find_by_presentation_name(project)
    end
    path = project_path(@project.name)
    open_domain path
  end

  def open_planning_page(project="Project 1", sprint="Sprint 2")
    DomainChecks.disable do
      @project = Project.find_by_presentation_name(project)
      @sprint = Sprint.find_by_name(sprint)
    end
    path = plan_project_sprint_path(@project.name, @sprint.id)
    open_domain path
  end

  def open_admin_page
    path = admin_panel_path
    open_domain path
  end

  def assign_users_to_task(task_summary, *users)
    DomainChecks.disable do
      @task = Task.find_by_summary(task_summary)
    end
    task_id = @task.id
    click "//li[@id='task-#{task_id}']//span[@class='user-login']"
    users.each do |u|
      click "//input[@alt='#{u}']"
    end
    click '//form[@class="editor-field"]//button[@type="submit"]'
  end
  
  def expand_impediments_container
    click '//div[@id="impediments-info-box"]/h2/a/div'
  end

  def click_create_impediment
    click "//div[@class='new-impediment']/p/input"
  end

  def assert_backlog_stats(total, estimates, effort)
    wait_for "getText(\"//span[@class=\'items-total-count\']\").normalize() == \"#{total}\""
    wait_for "getText(\"//span[@class=\'items-not-estimated-count\']\").normalize() == \"#{estimates}\""
    wait_for "getText(\"//span[@class=\'items-effort\']\").normalize() == \"#{effort}\""
  end

end

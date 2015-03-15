require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :comments

  fixtures :users, :projects, :roles, :role_assignments, :domains

  subject { @user }

  should_have_many :juggernaut_sessions

  def setup
    super
    Domain.current = domains(:code_sprinters)
    @user = users(:user_one)
  end
  subject { @user }

  def teardown
    super
    Domain.current = nil
    User.current = nil
  end

  def test_not_authenticate_wrong_password_user
    login = users(:user_one).login
    password = 'tojestzlehaslo'
    Domain.current = domains(:code_sprinters)
    assert_nil User.authenticate(login, password)
    Domain.current = nil
  end

  context 'user with comments' do
    setup do
      Domain.current = @domain = Factory.create(:domain)
      User.current = Factory.create(:user)
      @project = Factory :project
      @domain.projects << @project
      
      item = Factory.create(:item, :project => @project, :estimate => 3.0)
      @project.items << item

      comment = Factory.create(:comment, :user => @user, :domain => @domain, :item => item)
      @user.comments << comment
    end

    should 'have comments' do
      assert_not_nil @user.comments.first
    end

    context 'that was destroyed' do
      setup do
        @domain.users.first.delete
      end
      
      should_change("number of users", :to => 0) do
        @domain.reload.users.count
      end
    end
  end


  def test_authenticate_correct_password_user
    login = users(:user_one).login
    password = 'alamakota'
    Domain.current = domains(:code_sprinters)
    assert_equal users(:user_one), User.authenticate(login, password)
    Domain.current = nil
  end

  context 'New user' do
    setup do
      @attributes = { :login => 'annaczajka', :first_name => 'Anna', :last_name => 'Czajka', :user_password => 'makota', :email_address => 'aaa@op.pl', :domain => domains(:code_sprinters), :service_updates => true, :last_news_read_date => false, :terms_of_use => true, :new_offers => true, :type => 'Admin', :date_format_preference => 'DD-MM-YYYY'}
      @user = User.new(@attributes)

      @allowed_attributes = [:first_name, :last_name, :email_address, :service_updates, :last_news_read_date, :new_offers, :date_format_preference]
      @protected_attributes = @attributes.keys - @allowed_attributes
    end
    should 'set only accessible attributes' do
      @allowed_attributes.each do |attr|
        assert_equal @attributes[attr], @user[attr], "Setting #{attr}"
      end
    end

    should 'not set protected attributes' do
      @protected_attributes.each do |attr|
        assert_not_equal @attributes[attr], @user[attr], "Setting #{attr}"
      end
    end

    should 'have a default date prefference' do
      assert_equal("DD-MM-YYYY", @user.date_format_preference)
    end
  end

  def test_add_user
    user = User.new
    user.login = "annaczajka"
    user.first_name = "anna"
    user.last_name = "czajka"
    user.user_password = "makotaala"
    user.email_address = "aaa@op.pl"
    user.domain = domains(:code_sprinters)
    assert_nothing_raised(Exception) { user.save! }
    assert_not_nil(user.salt)
    assert_equal(User.encrypted_password('makotaala',user.salt), user.password)
    assert_equal("aaa@op.pl", user.email_address)
  end

  def test_add_duplicate_login
    user = users(:user_one)
    new_user = User.new
    new_user.login = users(:user_one).login
    new_user.first_name = "newFirstName"
    new_user.last_name = "newLastName"
    new_user.user_password = "newPassword"
    new_user.email_address = "halo@halo.com"
    assert user.valid?
    assert !new_user.save
  end

  def test_user_too_short_password
    user = User.new 
    user.login = "mswiatek"
    user.first_name = "Marcin"
    user.last_name = "Świątek"
    user.user_password = "yy"
    user.email_address = "uuu@aaa.pl"
    user.domain = domains(:code_sprinters)
    
  
    assert_not_valid(user)
    assert user.errors.invalid?(:user_password)

    user.user_password = "yyyyy"
    assert_valid(user)
  end

  def test_user_empty_values
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:first_name)
    assert user.errors.invalid?(:last_name)
    assert user.errors.invalid?(:login)
  end

  def test_email_valid
    user = users(:user_one)
    invalid = %w{name name.com name@domain 1221}
    invalid.each do |email|
      user.email_address = email
      assert !user.errors.invalid?(:email_address)
    end
  end

  def test_password_valid
    user = users(:user_one)
    invalid = %w{aDt4 lAla ue3! 23}
    invalid.each do |pwd|
      user.user_password = pwd
      user.valid?
      assert (user.errors.invalid?(:user_password))
    end
  end

  def test_full_name
    assert_equal(@user.full_name, "Ania Czajka")
  end

  def test_user_has_projects
    user = users(:janek)
    assert (user.projects.empty?)

    bm = users(:banana_master)
    assert (not bm.projects.empty?)
  end

  def test_admin_has_more_projects
    user = users(:admin)
    domain = domains(:code_sprinters)
    assert_kind_of Admin, user
    admin_projects = user.projects
    assert_same_elements domain.projects, admin_projects
  end

  def test_granting_admin_rights
    user = users(:user_two)
    assert (not user.admin?)
    user.grant_admin_rights
    user = User.find(user.id) # reload user
    assert_kind_of Admin, user
  end

  def test_revoking_admin_rights
    user = users(:admin)
    assert_kind_of Admin, user
    user.revoke_admin_rights
    user = User.find(user.id)
    assert (not user.admin?)
  end

  def test_setting_admin_rights
    user = users(:admin)
    user.admin = false
    assert_nil user.type
    user.admin = true
    assert_equal 'Admin', user.type
  end
  
  def test_blocking_user_account
    user = users(:block_user_account)
    user.block_user_account
    user = User.find(user.id)
    assert user.blocked, user
  end
  
  def test_unblocking_user_account
    user = users(:user_two)
    user.unblock_user_account
    user = User.find(user.id)
    assert !user.blocked, user
  end
  
  def test_switching_blocked
    user = users(:user_two)
    user.block_user_account
    assert user.blocked, user.reload
    user.switch_blocked
    assert !user.blocked, user.reload
    user.switch_blocked
    assert user.blocked, user.reload
  end
  
  # test reproducing #625
  def test_deleting_user_with_impediment_logs
    project = Factory :project, :domain => Domain.current
    user = Factory :user, :domain => Domain.current
    User.current = user
    project.add_user_with_role(user, Role.find_by_code('team_member'))
    impediment = Factory :impediment, :domain => Domain.current, :project => project
    assert impediment.valid?
    user.reload
    assert_equal 1, user.impediment_logs.length
    assert !user.destroy
    assert_match /Consider blocking the user instead/, user.errors.full_messages.first
  end
end

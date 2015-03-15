require File.dirname(__FILE__) + '/../test_helper'

class UserFormWithPasswordAssignmentTest < ActiveSupport::TestCase
  fixtures :roles

  context "A sample user form" do
    setup do
      @form = UserFormWithPasswordAssignment.new({ :user_password => 'aaaa', :user_password_confirmation => 'aaaa'})
    end

    should 'assign password field to user' do
      assert_equal 'aaaa',  @form.user.user_password
      assert_equal 'aaaa',  @form.user.user_password_confirmation
      assert @form.user.password_changed
    end
  end
end
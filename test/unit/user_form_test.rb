require File.dirname(__FILE__) + '/../test_helper'

class UserFormTest < ActiveSupport::TestCase
  fixtures :roles

  context "A sample user form" do
    setup do
      @form = UserForm.new
    end
    
    should 'Have user and assignemnt field' do
      assert_not_nil @form.user
      assert_not_nil @form.user_assignment_fields
    end
  end
  
  context "A form with only user fields" do
    setup do 
      Domain.current = Factory.create(:domain)
      @form = UserForm.new(:first_name => "aaa", :last_name => "bbb", :login => 'bacss', :email_address => "eeee@dl.pl")
    end
    
    should 'be valid' do
      assert @form.valid?
    end
    
    should "save" do
      assert_difference "User.count" do
        assert @form.save
      end
    end
  end
  
  context "A form with user fields and project assignments" do
    setup do
      Domain.current = Factory.create(:domain)
      @project = Factory.create :project
      @form = UserForm.new(
        :first_name => "aaa", 
        :last_name => "bbb", 
        :login => 'bacss', 
        :email_address => "eeee@dl.pl",
        :projects_to_assign => @project.id,
        :roles_to_assign => {
          roles(:team_member).id => '1'
        })
    end
    
    should "be valid and save" do
      assert @form.valid?
      assert_difference 'RoleAssignment.count', 1 do
        assert_difference 'User.count' do
          assert @form.save
        end
      end
    end
  end
  
  context "A form with user fields and incorrect project assignments" do
    setup do
      Domain.current = Factory.create(:domain)
      @form = UserForm.new(
        :first_name => "aaa", 
        :last_name => "bbb", 
        :login => 'bacss', 
        :email_address => "eeee@dl.pl",
        :roles_to_assign => {
          roles(:team_member).id => '1'
        }
      )
    end
      
    should "not be valid" do
      assert !@form.valid?
      assert_not_nil @form.errors.on(:to_assign)
    end
    
    should "not create user" do
      assert_no_difference 'User.count' do
        assert !@form.save
      end
    end
  end
end

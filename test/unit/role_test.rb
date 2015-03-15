require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < ActiveSupport::TestCase

  def test_creating_new_roles
    role = Role.new
    role.name = "Test role"
    role.description = "This is a new role"
    assert_valid role
    assert role.save
  end

  def test_reset_roles_to_default
    Role.reset_to_defaults
    assert_equal 0, RoleAssignment.count
    assert !Role.find(:all).empty?
    Role::DEFAULTS.each do |elem|
      assert_not_nil Role.find_by_name(elem[:name])
    end
    assert_equal Role::DEFAULTS.length, Role.find(:all).size
  end
end

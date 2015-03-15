require File.dirname(__FILE__) + '/../../test_helper'

class TasksHelperTest < HelperTestCase

  include TasksHelper
  fixtures :domains, :projects, :users, :roles, :role_assignments

  context "user_asignment_json_hash method" do
    setup do
      Domain.current = domains(:code_sprinters)
      User.current = users(:user_one)
      Project.current = projects(:bananorama)
    end
    
    should "return json hash with team members" do
      
      result = user_asignment_json_hash
      assert_not_nil result
      
      object = nil
      assert_nothing_raised { object = ActiveSupport::JSON.decode(result) }
      
      assert object.is_a? Array
      object.each do |choice|
        assert choice.is_a? Hash
        assert_not_nil choice["label"]
        assert_not_nil choice["name"]
        assert_not_nil choice["value"]
        
        assert Project.current.get_user_roles(choice["value"]).any? {|r| r.code == "team_member"}
        by_login = User.find_by_login(choice["label"])
        by_id = User.find_by_id(choice["value"])
        assert_not_nil by_login
        assert_not_nil by_id
        assert_equal by_login, by_id
      end

    end
  end
  

end

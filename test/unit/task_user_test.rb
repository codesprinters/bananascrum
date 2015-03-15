require File.dirname(__FILE__) + '/../test_helper'

class TaskUserTest < ActiveSupport::TestCase
  should_belong_to :task
  should_belong_to :user
  
  context "domain set" do
    setup { Domain.current = domains(:code_sprinters) }
    should_validate_uniqueness_of :user_id, :scoped_to => :task_id
  end
end

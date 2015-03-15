require File.dirname(__FILE__) + '/../test_helper'

# This is not a real test. We only check here if correct implementation is loaded

class EventMachineTest < ActiveSupport::TestCase
  def test_correct_implementation_loaded
    assert_equal :java, $eventmachine_library, "It seems that the eventmachine gem has not been built. It will make juggernaut crazy. Deal with it!"
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class StatRunTest < ActiveSupport::TestCase
  should_have_many :stat_data
  should_validate_presence_of :timestamp
end
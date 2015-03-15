require File.dirname(__FILE__) + '/../test_helper'

class LogFieldTest < ActiveSupport::TestCase
  should_belong_to :domain
  should_belong_to :log
end

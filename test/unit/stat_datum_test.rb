require File.dirname(__FILE__) + '/../test_helper'

class StatDatumTest < ActiveSupport::TestCase
  should_belong_to :stat_run
  should_validate_presence_of :stat_run, :value, :kind
end

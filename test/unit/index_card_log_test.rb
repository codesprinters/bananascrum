require File.dirname(__FILE__) + '/../test_helper'

class IndexCardLogTest < ActiveSupport::TestCase
  should_belong_to :domain
  should_validate_presence_of :contents, :collection_size
end

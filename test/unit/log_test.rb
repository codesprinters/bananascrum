require File.dirname(__FILE__) + '/../test_helper'

class LogTest < ActiveSupport::TestCase

  should_belong_to :sprint
  should_belong_to :item
  should_belong_to :task
  should_belong_to :user

  should_have_many :fields

end

require File.dirname(__FILE__) + '/../test_helper'

class DemoDataGeneratorTest < ActiveSupport::TestCase
  should 'run smoothly' do
    DemoDataGenerator.new.generate
  end
end

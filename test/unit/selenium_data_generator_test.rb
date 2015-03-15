require File.dirname(__FILE__) + '/../test_helper'

class SeleniumDataGeneratorTest < ActiveSupport::TestCase
  context 'Selenium Data Suite' do
    setup { @gen = SeleniumDataGenerator.new }
    should 'run smoothly' do
      @gen.generate
    end
  end
end
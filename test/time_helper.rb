# To add this helper to test, add following line to your test:
# require File.dirname(__FILE__) + '/../time_helper'


class Time 
  class << self
    attr_accessor :fake_time, :use_fake_time
    alias_method :real_now, :now
    def now
      use_fake_time ? fake_time : real_now
    end
    alias_method :new, :now
  end
end
Time.use_fake_time = false

class Test::Unit::TestCase
  def pretend_now_is(time)
    begin
      Time.fake_time = time
      Time.use_fake_time = true
      yield
    ensure
      Time.use_fake_time = false
    end
  end
end

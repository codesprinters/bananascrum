ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require "rubygems"
require 'test_help'

# Require helper tests
require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # Takes two date and checks if tested is in time delta from expected
  def assert_date_in_delta(expected, tested, time_delta) 
    assert_not_nil(expected, "Expected date can't be nil")
    assert_not_nil(tested, "Tested date can't be nil")
    start = expected - time_delta
    ending = expected + time_delta
    assert(tested.between?(start, ending), "#{tested} is not between #{start} and #{ending}") 
  end

  def assert_not_valid(obj)
    assert !obj.valid?, "Object #{obj} is valid (should not be)"
  end
  
  def uploaded_file(path, content_type="application/octet-stream", filename=nil)
    filename ||= File.basename(path)
    template = Tempfile.new(filename)
    FileUtils.copy_file(path, template.path)
    (class << template; self; end;).class_eval do
      alias local_path path
      define_method(:original_filename) { filename }
      define_method(:content_type) { content_type }
    end
    return template
  end

  def assert_select_on_envelope(*args, &block)
    envelope = nil 
    assert_nothing_raised do
      envelope = ActiveSupport::JSON.decode(@response.body)
    end
    assert_not_nil envelope['html']
    
    root = HTML::Document.new(envelope['html'], false).root
    assert_select(root, *args, &block)
  end

  def self.call_action_under_test(&block)
    context '' do
      setup do
        @action.call unless @action.nil?
        
        # set Domain.current @see DomainAndAuthorization#set_domain_to_nil
        Domain.current = @domain if @domain
      end

      merge_block(&block)
    end
  end

end

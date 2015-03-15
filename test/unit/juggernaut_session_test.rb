require File.dirname(__FILE__) + '/../test_helper'

class JuggernautSessionTest < ActiveSupport::TestCase

  context 'A new instance' do
    setup do
      @session = JuggernautSession.new   
    end

    should_allow_mass_assignment_of :user, :project
    should_belong_to :user, :project
    should_have_many :locked_items

  end

  context 'Saved instance' do
    fixtures :domains, :users, :projects
    setup do
      @domain = domains(:code_sprinters)
      Domain.current = @domain
      @user = users(:user_one)
      @project = projects(:bananorama)
      JuggernautCache.any_instance.stubs(:current_id).returns(5)
      @session = JuggernautSession.create!(:user => @user, :project => @project)
    end

    should 'have subscribed_at set to nil' do
      assert_nil @session.subscribed_at
    end
    
    should 'have initial message id set' do
      assert_equal 5, @session.initial_message_id
    end

    should 'set subscribed at to now when subscribed' do
      time = "2009-06-15 10:15:44".to_time
      Time.stubs(:now).returns(time)
      @session.subscribed
      assert_equal time, @session.reload.subscribed_at
    end

  end

end

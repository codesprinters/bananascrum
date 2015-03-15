require File.dirname(__FILE__) + '/../test_helper'

require 'singleton'

class JuggernautCacheTest < ActiveSupport::TestCase
  fixtures :projects
  
  context 'Cache stores messages' do
    setup do
      Juggernaut.stubs(:send_to_channels)
      Rails.cache.clear
      @instance = JuggernautCache.instance
      @instance.send(:initialize)
      #reset id
      DomainChecks.disable do
        @project = projects(:bananorama)
        @session = Factory(:juggernaut_session)
      end
    end
    
    should 'have current_id set to 0' do
      assert_equal 0, @instance.current_id
    end
    
    should 'increase id when broadcasts message' do
      Juggernaut.expects(:send_to_channels).once
      @instance.broadcast('some message', [@project.id])
      assert_equal 1, @instance.current_id
    end
    
    context 'Getting stored messages' do
      setup do
        DomainChecks.disable do
          @other_project = projects(:second)
          @other_session = Factory(:juggernaut_session, :project => @other_project, :user => @other_project.users.first)
        end
      end
    
      should 'return messages only for our project' do 
        assert_equal 0, @session.initial_message_id
        assert_equal 0, @other_session.initial_message_id
        @instance.broadcast('some message', [@project.id])
        @instance.broadcast('message to other project', [@other_project.id])
        @instance.broadcast('some other message', [@project.id])
        @instance.broadcast('another message to other project', [@other_project.id])
        
        assert_equal 4, @instance.current_id
        messages = @instance.get_scheduled_messages(@session)
        assert messages.is_a? Array
        assert_equal 2, messages.length
        assert messages.first.is_a? JuggernautMessage
        assert_equal 'some message', messages.first.body
        assert_equal 'some other message', messages.last.body
        
        other_messages = @instance.get_scheduled_messages(@other_session)
        assert_equal 2, other_messages.length
        assert_equal 'message to other project', other_messages.first.body
        assert_equal 'another message to other project', other_messages.last.body
      end
    end
  end
end

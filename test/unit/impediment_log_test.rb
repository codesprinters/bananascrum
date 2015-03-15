require File.dirname(__FILE__) + '/../test_helper'

class ImpedimentLogTest < ActiveSupport::TestCase
  fixtures :impediments, :impediment_actions, :impediment_logs, :users
  
  
  def setup
    Domain.current = domains :code_sprinters
  end
  
  def teardown
    User.current = nil
    Domain.current = nil
  end
  
  def test_parent_gets_updated
    i = impediments(:open)
    log = ImpedimentLog.new
    log.impediment = i
    log.impediment_action = impediment_actions(:closed)

    log.user = users(:user_one)

    class << log
      alias_method :update_parent_real, :update_parent
      public :update_parent_real
    end
    
    log.expects(:update_parent).once().with{log.update_parent_real; true}
    
    log.save!

    assert ! i.is_open
  end
  
  def test_same_project
    DomainChecks.disable do
      i = impediments(:open)
      u = users(:dilbert) # cross domain fails

      assert i.project.domain != u.domain

      log = ImpedimentLog.new
      log.impediment = i
      log.impediment_action = impediment_actions(:closed)
      log.user = u

      assert ! log.valid?

      u = users(:janek) # cross project fails
      log.user = u

      assert i.project.domain == u.domain
      assert ! u.projects.include?(i.project)
      assert ! log.valid?

      u = users(:user_one) # cross project fails
      assert u.projects.include?(i.project)
      log.user = u
      assert log.valid?
    end
  end
  
  def test_validates_state
    i = impediments(:open)
    log = ImpedimentLog.new
    log.impediment = i
    log.user = users(:user_one)
    
    log.impediment_action = impediment_actions(:reopened)
    assert ! log.valid?
    
    log.impediment_action = impediment_actions(:created)
    assert ! log.valid?
    
    log.impediment_action = impediment_actions(:commented)
    assert ! log.valid?
    log.comment = 'blah'
    assert log.valid?
    
    log.impediment_action = impediment_actions(:closed)
    assert log.valid?
    log.save!
    
    log = ImpedimentLog.new
    log.impediment = i.reload
    log.user = users(:user_one)
    
    
    log.impediment_action = impediment_actions(:closed)
    assert ! log.valid?
    
    log.impediment_action = impediment_actions(:reopened)
    assert log.valid?
  end
end

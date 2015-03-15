require File.dirname(__FILE__) + '/../test_helper'

class ImpedimentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def setup
    super
    Domain.current = domains :code_sprinters
    User.current = users(:user_one)
  end
  
  def teardown
    User.current = nil
    Domain.current = nil
    super
  end
  
  def test_creation
    impediment = Impediment.new
    impediment.project = projects(:bananorama)
    impediment.summary = "Need more coffee"
    impediment.description = "I need more coffee to work effectively"
    
    impediment.save!
    impediment.reload
    
    assert impediment.impediment_logs.size == 1
    
    assert impediment.is_open
  end
  
  def test_cross_domain_creation
    DomainChecks.disable do
      impediment = Impediment.new
      impediment.project = projects(:first_in_abp_domain)
      impediment.summary = "This should fail"
      assert impediment.valid?
      assert_raise(ActiveRecord::RecordInvalid) { impediment.save! }
      assert_nil impediment.id
      assert impediment.new_record?
    end
  end
  
  def test_process
    impediment = Impediment.new
    impediment.project = projects(:bananorama)
    impediment.summary = "I have no root and I must scream"
    impediment.save!
    impediment.reload
    
    assert impediment.impediment_logs.size == 1
    assert impediment.is_open
    
    impediment.comment("Hello world!")
    assert impediment.impediment_logs.size == 2
    assert impediment.is_open
    
    impediment.close("Closed")
    impediment.reload
    assert impediment.impediment_logs.size == 3
    assert ! impediment.is_open
        

    impediment.comment("Hello world, again!")
    impediment.reload
    assert impediment.impediment_logs.size == 4
    assert ! impediment.is_open
    
    impediment.reopen("Why?")
    impediment.reload
    assert impediment.impediment_logs.size == 5
    assert impediment.is_open
    
    # Can;t reopen already open impediment
    assert_raise ActiveRecord::RecordInvalid do
      impediment.reopen("aaaaaaaa")
    end
    
    assert impediment.impediment_logs.size == 5
    assert impediment.is_open
    
    impediment.close("Closed")
    impediment.reload
    assert impediment.impediment_logs.size == 6
    assert impediment.impediment_logs.count == 6
    assert ! impediment.is_open
    
    # Can't close already clsoed impediment
    assert_raise ActiveRecord::RecordInvalid do
      assert ! impediment.close("aaaaaaaa").valid?
    end
    
    assert impediment.impediment_logs.size == 6
    assert impediment.impediment_logs.count == 6
    assert ! impediment.is_open
  end
  
  def test_creator
    imp = impediments(:open)
    assert_nil imp.creator
    log = impediment_logs(:open_created)
    log.user = users(:user_one)
    log.save!
    
    imp = imp.reload
    
    assert_equal users(:user_one), imp.creator
    
    log.destroy
    imp =imp.reload
    
    assert_nil imp.creator
  end
end

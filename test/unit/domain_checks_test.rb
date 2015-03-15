require File.dirname(__FILE__) + '/../test_helper'

class DomainChecksTest < ActiveSupport::TestCase
  
  def setup
    super
    Domain.current = nil
    User.current = nil
  end
  
  def teardown
    Domain.current = nil
    User.current = nil
    super
  end
  
  def test_objects_cant_be_loaded_without_domain
    Domain.current = nil
    User.current = nil
    assert_raise SecurityError do
      User.find :first
    end
  end
  
  def test_objects_cant_be_loaded_from_wrong_domain
    Domain.current = domains :code_sprinters
    
    assert_nothing_raised do
      users :user_one
    end
    
    assert_raise SecurityError do
      users :dilbert
    end
  end
  
  def test_new_objects_automatically_set_domain
    Domain.current = domains :code_sprinters
    user = User.new
    user.valid?
    
    assert_not_nil user.domain
    assert_equal domains(:code_sprinters), user.domain
  end
  
  def test_cant_save_to_other_domain
    Domain.current = domains(:code_sprinters)
    
    user = User.new
    user.login = 'user_for_crossdomain_checks'
    user.user_password = 'alamaakota'
    user.email_address = 'pstradomski@codesprinters.com'
    user.first_name = 'John'
    user.last_name = 'Testing'
    
    assert user.valid?
    
    user.domain = domains(:airbites)
    
    assert user.valid?
    
    assert_raise SecurityError do
      user.save
    end
    
    Domain.current = nil
    assert_raise SecurityError do
      user.save
    end
    
    Domain.current = user.domain
    assert_nothing_raised do
      user.save
    end
    
    assert !user.new_record?
  end
  
  def test_cant_delete_from_other_domain
    Domain.current = domains(:code_sprinters)
    
    user = User.new
    user.login = 'user_for_crossdomain_checks'
    user.user_password = 'alamaakota'
    user.email_address = 'pstradomski@codesprinters.com'
    user.first_name = 'John'
    user.last_name = 'Testing'
    assert user.save
    
    user.domain = domains(:airbites)
    
    assert_raise SecurityError do
      user.destroy
    end
  end
  
  def test_can_disable_checks
    Domain.current = nil
    DomainChecks.disable do
      user = User.new
      user.login = 'user_for_crossdomain_checks'
      user.user_password = 'alamaakota'
      user.email_address = 'pstradomski@codesprinters.com'
      user.first_name = 'John'
      user.last_name = 'Testing'
      user.domain = domains :airbites

      assert user.save
      
      user.domain = domains :code_sprinters
      
      assert user.save
      
      assert user.destroy
    end
  end
end

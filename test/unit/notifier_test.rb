require File.dirname(__FILE__) + '/../test_helper'

class NotifierTest < ActionMailer::TestCase
  tests Notifier
  fixtures :users, :domains
  
  def test_reset_password
    begin
      Domain.current = domains(:code_sprinters)
      user = users(:admin)
      key = "traladupala"
      
      response = Notifier.create_reset_password(user, key)
      assert_nothing_raised(Exception) do
        Notifier.deliver_reset_password(user,key)
      end
      assert_not_nil(response.body) 
      assert_match("/new?key="+key, response.body)
    ensure
      Domain.current = nil
    end
  end
  
  def test_new_user
    begin
      Domain.current = domains(:code_sprinters)

      user = users(:user_one)
      user_activation = user.user_activations.create(:reset_pwd => true)
      user_activation.save!

      user.note_for_user = 'Wilkommen aus das projekt!'
      response = Notifier.create_new_user(user, user_activation.key )
      assert_nothing_raised(Exception) do
        Notifier.deliver_new_user(user, user_activation.key)
      end
      assert_not_nil(response.body) 
      assert_match(user_activation.key, response.body)
      assert_match(user.note_for_user, response.body)
    ensure
      Domain.current = nil
    end
  end

end

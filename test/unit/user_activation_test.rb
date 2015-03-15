require File.dirname(__FILE__) + '/../test_helper'

class UserActivationTest < ActiveSupport::TestCase
fixtures :users

  def setup
    super
    Domain.current = domains(:code_sprinters)
    User.current = users(:user_one)
  end

  def teardown
    super
    Domain.current = nil
    User.current = nil
  end
  
  def test_generating_key
    john = users(:user_one)
    john.login = "johnjohn_unique_johnjohn"
    john.save!
    john.user_activations.create

    activation = john.user_activations.first
    assert_not_nil(activation.key)

    john.destroy
    UserActivation.exists?(activation)
  end

  # test reproduction #626, double submit of registration form fooled the uniqueness validation and ended in StatementInvalid 
  def test_many_threads_creating_activations
    @user = User.current
    @domain = Domain.current
    threads = [1, 2].map do
      Thread.new do
        assert_nothing_raised do
          Domain.current = @domain
          activation = @user.user_activations.create
          assert activation.valid?
        end
      end
    end
    threads.each { |thread| thread.join }
  end
end

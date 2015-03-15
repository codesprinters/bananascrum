require File.dirname(__FILE__) + '/../test_helper'

class DeleteRequestTest < ActiveSupport::TestCase
  context 'Delete request instance' do
    setup do
      @domain = Domain.current = Factory.create(:domain)
      @user = Factory.create(:user, :domain => @domain)
      @delete_request = DeleteRequest.create!(:user => @user, :domain => @domain)
    end

    subject { @delete_request }

    should_belong_to :domain
    should_belong_to :user
    should_validate_uniqueness_of :key

    should('have date set') { assert_not_nil @delete_request.created_at }

    should('set key after create') { assert_not_nil @delete_request.key }
    end
  end

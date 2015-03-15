require File.dirname(__FILE__) + '/../test_helper'

class LicenseTest < ActiveSupport::TestCase

  context 'A License instance' do
    setup do
      Thread.current[:domain_checks_suspended] = true
      Domain.current = @domain = Factory.create(:domain)
      @license = Factory.create(:company_license, :domain => @domain)
    end

    teardown do
      Thread.current[:domain_checks_suspended] = false
    end
    
    subject { @license }

    should_belong_to :domain
    should_validate_presence_of :domain, :key, :entity_name
    should_validate_uniqueness_of :domain_id
  end

end

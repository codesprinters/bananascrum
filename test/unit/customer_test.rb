require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < ActiveSupport::TestCase
  should_have_one :domain
  should_have_one :plan, :through => :domain
  should_have_many :payments
  should_have_many :invoices

  context 'Step1 validations' do
    should 'Require contry code and account type upon creating' do
      customer = Customer.new(:form_step => 'step1', :country_code => 'PL', :account_type => 'personal')
      assert customer.valid?
      assert customer.polish?
      assert !customer.company
      
      customer = Customer.new(:form_step => 'step1', :country_code => 'PL', :account_type => 'company')
      assert customer.valid?
      assert customer.company
      assert customer.polish?
      
      customer = Customer.new(:form_step => 'step1', :account_type => 'company')
      assert !customer.valid?
      assert customer.errors.on(:country_code)
      
      customer = Customer.new(:form_step => 'step1', :country_code => 'PL')
      assert !customer.valid?
      assert customer.errors.on(:account_type)
      assert customer.polish?
    end
    
    should 'should not save' do
      customer = Customer.new(:form_step => 'step1', :country_code => 'PL', :account_type => 'personal')
      assert customer.valid?
      assert !customer.save
    end
  end
  
  context 'european? method' do
    should 'Return proper result' do
      customer = Customer.new(:form_setp => 'step1', :country_code => 'PL')
      assert customer.european?
      
      customer = Customer.new(:form_setp => 'step1', :country_code => 'GB')
      assert customer.european?
      
      customer = Customer.new(:form_setp => 'step1', :country_code => 'US')
      assert !customer.european?
      
      customer = Customer.new(:form_setp => 'step1', :country_code => 'CA')
      assert !customer.european?
    end
  end

  context 'A Customer instance' do
    setup { @customer = Factory.build(:customer) }
    subject { @customer }

    should_validate_presence_of :name
    should_validate_presence_of :email
    should_validate_presence_of :phone
    should_validate_presence_of :country
    should_validate_presence_of :city
    should_validate_presence_of :postcode
    should_validate_presence_of :street_line1

    should 'validate email' do
      valid_emails = ['a@b.com', 'john.doe@gmail.com']
      for email in valid_emails
        @customer.email = email
        assert @customer.valid?
      end

      invalid_emails = ['', 'a', 'john do@gmail.com', '@foo.com', 'foo@']
      for email in invalid_emails
        @customer.email = email
        assert !@customer.valid?
        assert @customer.errors.invalid?(:email)
      end
    end

    context 'with company' do
      setup { @customer.company = true }
      subject { @customer }
      
      should_validate_presence_of :name
    end

    context 'in europe' do
      setup { @customer.country = "PL" }
      subject { @customer }
      should_validate_presence_of :tax_number
    end

    should 'return full name' do
      @customer.name = 'Lukasz Bandzarewicz'

      assert_equal 'Lukasz Bandzarewicz', @customer.full_name
    end

    should 'return address' do
      @customer.street_line1 = 'Syrokomli 22/6'

      expected_address = "Syrokomli 22/6"
      assert_equal expected_address, @customer.address
    end
  end

  context 'polish?' do
    setup { @customer = Factory.build(:customer) }

    context 'for Customer in Poland' do
      setup { @customer.country = 'PL' }
      should('return true') { assert @customer.polish? }
    end
    
    context 'for Customer beyond Poland' do
      setup { @customer.country = 'GB' }
      should('return false') { assert !@customer.polish? }
    end
  end

  context 'european?' do
    setup { @customer = Factory.build(:customer) }

    context 'for Customer in Europe' do
      setup { @customer.country = Customer::UE_CODES.rand }
      should('return true') { assert @customer.european? }
    end

    context 'for Customer beyond Europe' do
      setup { @customer.country = 'US' }
      should('return false') { assert !@customer.european? }
    end
  end

  context 'company?' do
    setup { @customer = Factory.build(:customer) }

    context 'for Customer with company' do
      setup { @customer.company = true }
      should('return true') { assert @customer.company? }
    end

    context 'for Customer without company' do
      setup { @customer.company = false }
      should('return false') { assert !@customer.company? }
    end
  end

  context 'pays_with_vat?' do
    setup { @customer = Factory.build(:customer) }

    context 'for Customer in Poland' do
      setup { @customer.country = 'PL' }
      should('return true') { assert @customer.pays_with_vat? }
    end

    context 'for Customer in Europe except Poland' do
      setup { @customer.country = Customer::UE_CODES.reject { |code| code == 'PL' }.rand }

      context 'without company' do
        setup { @customer.company = false }
        should('return true') { assert @customer.pays_with_vat? }
      end

      context 'with company' do
        setup { @customer.company = true }
        should('return false') { assert !@customer.pays_with_vat? }
      end
    end

    context 'for Customer beyond Europe' do
      setup { @customer.country = 'US' }
      should('return false') { assert !@customer.pays_with_vat? }
    end
  end
end

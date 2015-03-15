class Customer < ActiveRecord::Base

  UE_CODES = %w(AT BE BG CY CZ DK EE FI FR FX TF GR ES AN NL IE LT LU LV MT DE PL PT RO SK SI SE HU GB IT).freeze

  has_one :domain
  has_one :plan, :through => :domain
  has_many :plan_changes, :order => 'created_at'
  has_many :payments, :order => 'to_date ASC'
  has_many :invoices, :through => :payments

  with_options :if => Proc.new { |obj| obj.form_step == 'step1' } do |customer|
    customer.validate :country_code_selected
    customer.validate :account_type_selected
  end
  
  with_options :unless => Proc.new { |obj| obj.form_step == 'step1' || obj.dummy } do |customer|
    customer.validates_presence_of :street_line1
    customer.validates_presence_of :country
    customer.validates_presence_of :city
    customer.validates_presence_of :phone
    customer.validate :phone_type_selected
    customer.validates_presence_of :name
    customer.validates_presence_of :postcode
    customer.validates_presence_of :email
    customer.validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    customer.validates_presence_of :tax_number, :if => Proc.new { |obj| obj.european? }
  end
  
  before_save :ensure_record_from_step_one_not_saved
  attr_accessor :form_step
  attr_accessible :form_step, :name, :email, :city, :country_code, :postcode, :street_line1, :street_line2,
    :phone, :phone_type, :tax_number, :state, :account_type

  def account_type=(type)
    return unless self.dummy
    self.company = case(type)
      when "company" then true
      when "personal" then false
      else nil
    end
  end
  
  def account_type
    self.company ? 'company' : 'personal'
  end
  
  def country_code=(code)
    return unless self.dummy
    self.country = code
  end
  
  def country_code
    self.country
  end
  
  def phone_type=(type)
    self.mobile_phone = (type == 'mobile')
  end
  
  def phone_type
    self.mobile_phone ? 'mobile' : 'stationary'
  end

  def european?
    UE_CODES.include?(self.country)
  end

  def polish?
    self.country == 'PL'
  end

  def pays_with_vat?
    polish? || (european? && !company?)
  end

  def full_name
    name
  end

  def entity_name
    company ? company_name : full_name
  end

  def address
    [street_line1, street_line2].compact.join("\n")
  end

  protected
  def phone_type_selected
    return unless self.mobile_phone.nil?
    errors.add(:phone_type, 'needs to be selected')
  end
  
  def ensure_record_from_step_one_not_saved
    if self.form_step == 'step1'
      return false
    end
  end

  def country_code_selected
    unless self.country 
      errors.add(:country_code, 'is required')
    end
  end
  
  def account_type_selected
    if self.company.nil?
      errors.add(:account_type, 'needs to be selected')
    end
  end

end

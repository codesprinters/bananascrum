class License < ActiveRecord::Base
  include DomainChecks # security checks

  belongs_to :domain

  validates_presence_of :domain, :entity_name, :key
  validates_uniqueness_of :domain_id
  validate :validate_key, :unless => Proc.new { |license| license.key.blank? }

  def rsa_key
    LicenseKey::Validator.new(key)
  end

  def has_valid_key?
    key = rsa_key
    current_date = Date.today
    data_check = key.valid? && (key.entity_name == entity_name) && (key.valid_to == valid_to)
    date_check = key.valid_to ? (current_date <= key.valid_to) : true
    return (data_check && date_check)
  end

  protected

  def validate_key
    errors.add(:key, "is invalid") unless has_valid_key?
  end
end

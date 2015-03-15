class Payment < ActiveRecord::Base
  belongs_to :domain
  belongs_to :customer
  belongs_to :plan
  has_one :invoice
  has_many :paypal_ipn_logs

  FREE_TRIAL_PERIOD = 30.days
  
  STATUSES = {
    :unpaid => 'unpaid',
    :paid => 'paid',
    :cancelled => 'cancelled',
  }

  named_scope :paid, :conditions => { :status => STATUSES[:paid] }
  named_scope :unpaid, :conditions => { :status => STATUSES[:unpaid] }
  named_scope :outstanding, :conditions => ['to_date < ?', Date.today]

  attr_protected :status
  before_validation_on_create :set_initial_values

  validates_presence_of :amount, :status, :plan, :customer
  validates_presence_of :issue_date, :from_date, :to_date
  validates_numericality_of :amount, :greater_than_or_equals => 0
  validates_inclusion_of :status, :in => STATUSES.values

  def validate
    if self.to_date and self.from_date then
      errors.add(:to_date, "should be greater than from_date") unless self.to_date > self.from_date
    end
  end

  def set_initial_values
    self.issue_date ||= Date.today
    self.status ||= Payment::STATUSES[:unpaid]
  end

  STATUSES.each do |key, value|
    define_method(:"#{key}?") do
      status == value
    end

    define_method(:"#{key}!") do
      update_attribute(:status, value)
    end
  end

end

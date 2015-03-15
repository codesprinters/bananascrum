module DomainPlansAndPayments

  BILLING_AGREEMENT_STATUSES = {
    :not_required => nil, # in case of free plan
    :waiting => 'waiting', # waiting for user to comple payment
    :completed => 'completed', # transaction is completed, we have cc_hash for rebilling
    :cancelled => 'cancelled',
    :blocked => 'blocked', # couldn't receive last payment, domain is blocked and can make instant payment only
    :failed => 'failed' # error response from gateway or transaction is not completed
  }.freeze

  DEBTOR_WARNINGS = {
    :first_warning => "first_warning",
    :second_warning => "second_warning",
    :domain_blocked => "domain_blocked"
  }.freeze

  # number of days after which warnings should be sent to user
  # it is number of days after to_date from most recent payment for this domain
  DEBTOR_WARNING_DAYS = {
    :first_warning => 1,
    :second_warning => 6,
    :domain_blocked => 8
  }.freeze

  def self.included(base)
    base.belongs_to :plan
    base.belongs_to :customer
    base.has_many :plan_changes, :order => 'created_at'
    base.has_many :payments, :order => 'to_date ASC'
    base.has_many :invoices
    base.has_many :paypal_ipn_logs

    base.validates_presence_of :plan
    base.validates_associated :plan
    base.validate :validate_plan_change, :unless => :force_changes
    base.validates_uniqueness_of :customer_id, :unless => Proc.new { |d| d.customer_id.nil? }
    base.validates_presence_of :customer

    base.attr_protected :billing_start_date, :plan

    base.before_validation_on_create :generate_dummy_customer

    base.class_eval do
      attr_accessor :force_changes
      attr_protected :force_changes

      BILLING_AGREEMENT_STATUSES.each do |key, value|
        define_method(:"billing_agreement_#{key}?") do
          self.billing_agreement_status == value
        end

        define_method(:"billing_agreement_#{key}!") do
          update_attribute(:billing_agreement_status, value)
        end
      end
    end
    
    def days_to_blockage
      payment = self.payments.unpaid.outstanding.last
      if payment
        payment.to_date + Domain::DEBTOR_WARNING_DAYS[:domain_blocked].days - Date.today
      else
        nil
      end
    end
    
    base.send(:extend, ClassMethods)
  end

  module ClassMethods
    def downgrading?(old_plan, new_plan)
      return if old_plan.nil?
      return !old_plan.free? && (new_plan.free? || old_plan.price > new_plan.price)
    end

    def upgrading?(old_plan, new_plan)
      return if old_plan.nil?
      !downgrading?(old_plan, new_plan)
    end
  end

  def generate_dummy_customer
    return if self.customer
    self.customer = Customer.new(:dummy => true)
  end

  def validate_plan_change
    if plan and plan_id_changed?
      errors.add(:plan, "can't be changed - this plan is not active now") unless plan.enabled?
      errors.add(:plan, "can't be changed - you have unpaid upgrade") unless can_change_plan?(old_plan, plan)
    end
  end

  def can_change_plan_to?(new_plan)
    can_change_plan?(plan, new_plan)
  end

  def can_downgrade?
    return false unless (self.billing_agreement_completed? || self.billing_agreement_cancelled? || self.billing_agreement_blocked?)

    last_upgrade_date = self.last_upgrade_date
    last_payment = self.payments.paid.last

    if last_payment
      if last_upgrade_date
        return last_payment.from_date >= last_upgrade_date.to_date
      else
        if self.billing_start_date
          return last_payment.from_date >= self.billing_start_date.to_date
        else
          return true
        end
      end
    else
      return false
    end
  end

  def last_upgrade_date
    last_upgrade = plan_changes.select { |pc| pc.upgrade? }.last
    return last_upgrade.try(:created_at)
  end

  def can_change_plan?(old_plan, plan)
    if Domain.downgrading?(old_plan, plan)
      return can_downgrade?
    else
      # upgrade is always possible
      return true
    end
  end

  def old_plan
    Plan.find(plan_id_was) if plan_id_was
  end

  def carry_out_plan_change
    Domain.transaction do
      plan_change = self.plan_changes.pending.last

      if plan_change
        # update plan, change pending flag
        self.plan = plan_change.new_plan
        self.update_attribute(:plan, plan_change.new_plan)

        plan_change.pending = false
        plan_change.save!
      end
    end
  end

  def pending_plan
    pending_plan_change = self.plan_changes.pending.last
    return pending_plan_change ? 
      Plan.find(pending_plan_change.new_plan_id) :
      self.plan # should not happen but well..
  end

  def log_plan_change(old_plan, new_plan)
    PlanChange.delete_all(["domain_id = ? AND pending = 1", Domain.current.id])
    plan_change = PlanChange.new(:pending => true, :user => User.current, :domain => self)
    plan_change.old_plan_id = old_plan.id if old_plan
    plan_change.new_plan_id = new_plan.id

    return plan_change.save
  end

  def force_payment?
    self.billing_agreement_waiting? || self.billing_agreement_failed? || self.billing_agreement_blocked?
  end

  def debtor?
    self.debtor
  end

  def make_downgradable
    raise "Method only for testing purposes" if Rails.env == 'production'

    self.update_attribute(:billing_start_date, 2.month.ago)
    self.plan_changes.delete_all

    payment = Payment.new(:customer => self.customer,
      :domain => self,
      :amount => self.plan.price,
      :plan => self.plan,
      :issue_date => Date.today,
      :from_date => 1.month.ago, :to_date => 1.day.ago)
    payment.status = Payment::STATUSES[:paid]
    payment.save!
  end

  # Compute billing start date for PayPal
  # The date when billing for this profile begins.
  # The profile may take up to 24 hours for activation.
  def billing_start_date_for_agreement
    if self.billing_start_date.nil?
      return initialize_billing_start_date
    else
      return shift_billing_start_date
    end
  end

  protected

  def initialize_billing_start_date
    current_time = Time.now
    
    if trial_period_used?
      return current_time + 1.day
    else
      return current_time + Payment::FREE_TRIAL_PERIOD
    end
  end

  def shift_billing_start_date
    current_time = Time.now

    if current_time < self.billing_start_date
      # this will include free trial period
      return self.billing_start_date
    else
      billing_day = self.billing_start_date.mday
      start_date = current_time.clone.change(:day => billing_day)

      if current_time >= start_date
        start_date = start_date + 1.month
      end
      
      return start_date
    end
  end


end

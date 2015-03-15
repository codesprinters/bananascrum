class DebtorFinder
  attr_reader :first_warning_domains, :second_warning_domains, :domain_blocked_domains, :domains, :messages

  def initialize
    @first_warning_domains = []
    @second_warning_domains = []
    @domain_blocked_domains = []
    @messages = []
  end

  def run
    prepare_collections
    handle_first_warning
    handle_second_warning
    handle_domain_blocking
  end

  def prepare_collections
    DomainChecks.disable do
      @domains = Domain.with_paid_plans

      Domain.transaction do
        @domains.each do |domain|
          payment = domain.payments.paid.find(:first, :order => "to_date DESC")
          date = payment.try(:to_date) || domain.billing_start_date
          case date
          when Domain::DEBTOR_WARNING_DAYS[:first_warning].days.ago.to_date
            @first_warning_domains << hash_for_domain(domain, date, payment)
          when Domain::DEBTOR_WARNING_DAYS[:second_warning].days.ago.to_date
            @second_warning_domains << hash_for_domain(domain, date, payment)
          when Domain::DEBTOR_WARNING_DAYS[:domain_blocked].days.ago.to_date
            @domain_blocked_domains << hash_for_domain(domain, date, payment)
          end
        end
      end
    end
  end

  def hash_for_domain(domain, date, payment)
    {:domain => domain, :to_date => date, :amount => payment ? payment.amount : domain.plan.price}
  end

  def handle_first_warning
    return unless @first_warning_domains
    mark_as_debtor_and_notify(@first_warning_domains, Domain::DEBTOR_WARNINGS[:first_warning])
  end

  def handle_second_warning
    return unless @second_warning_domains
    mark_as_debtor_and_notify(@second_warning_domains, Domain::DEBTOR_WARNINGS[:second_warning])
  end

  def handle_domain_blocking
    return unless @domain_blocked_domains
    mark_as_debtor_and_notify(@domain_blocked_domains, Domain::DEBTOR_WARNINGS[:domain_blocked]) do |domain|
      set_paypal_agreement_as_suspended(domain)
      domain.billing_agreement_blocked!
    end
  end

  private

  def mark_as_debtor_and_notify(domains, warning_type)
    domains.each do |hash|
      Domain.transaction do
        domain = hash[:domain]
        domain.warning = warning_type
        domain.debtor = true
        Domain.current = domain
        Notifier.send("deliver_debtor_#{warning_type}".to_s, domain, hash[:to_date], hash[:amount])
        yield(domain) if block_given?
        domain.save!
      end
    end
  end
  def set_paypal_agreement_as_suspended(domain)
    paypal_credentials = AppConfig.paypal[:credentials]
    gateway ||= ActiveMerchant::Billing::PaypalExpressRecurringGateway.new(paypal_credentials)

    response = gateway.suspend_profile(domain.billing_profile_id)
    if response.success?
      @messages << "Marked domain of name: #{domain.name} id:#{domain.id} paypal profile as suspended"
    else
      @messages << "Couldn't contact paypal to suspend account of domain: #{domain.name}, id: #{domain.id}\n"
    end
  end
end

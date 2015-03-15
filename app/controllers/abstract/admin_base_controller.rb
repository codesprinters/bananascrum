# Base controller for all admin actions
class AdminBaseController < DomainBaseController
  before_filter :redirect_if_not_admin, :find_domain

  protected

  def changing_plans_enabled
    render_404 unless AppConfig.payments_enabled
  end

  def prepare_users
    @users = Domain.current.users
  end

  def prepare_projects
    @projects = User.current.projects
  end

  def prepare_payments
    if AppConfig.payments_enabled
      @payments = Domain.current.payments
    end
  end

  def prepare_plans
    if AppConfig.payments_enabled
      @current_plan = @domain.plan
      @plans = Plan.enabled.public.find(:all, :order => "price ASC")
      @free_plan = @plans.select { |plan| plan.name == 'Free' }.first

      @not_available_plans = {}
      for plan in @plans
        exceedings = @domain.exceedes_plan?(plan)
        if exceedings
          @not_available_plans[plan] = exceedings
        end
      end

      @show_free_plan = (@current_plan != @free_plan) && (@current_plan.free? || Domain.current.can_downgrade?) && @not_available_plans[@free_plan].nil?
    end
  end

  def prepare_customer
    @customer = @domain.customer 
  end

  def find_domain
    @domain = Domain.current
  end

  def redirect_if_not_xhr
    unless request.xhr?
      flash[:warning] = "Only xhr requests allowed"
      redirect_to admin_panel_url
    end
  end

  protected

  def setup_gateway
    paypal_credentials = AppConfig.paypal[:credentials]
    @gateway ||= ActiveMerchant::Billing::PaypalExpressRecurringGateway.new(paypal_credentials)
  end

  def cancel_agreement_for(domain)
    response = @gateway.cancel_profile(domain.billing_profile_id)
    
    if response.success?
      domain.billing_profile_id = nil
      domain.billing_agreement_status = Domain::BILLING_AGREEMENT_STATUSES[:cancelled]
      domain.save!
    end

    return response
  end

end

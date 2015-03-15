class Admin::DomainsController < AdminBaseController
  helper Admin::PlansHelper
  
  def update
    domain_updated = @domain.update_attributes(params[:domain])

    if domain_updated then
      return render_json(200)
    else
      return render_json(409, :_error => { :message => @domain.errors.full_messages.join })
    end
  end

  def show
    prepare_plans
    prepare_domain
  end
end

module Admin::PlansHelper
  INFINITY_ENTITY = "&#8734;"
  EURO_ENTITY = "&#8364;"

  def plan_price(price)
    if price
      format_price(price)
    else
      "Free!"
    end
  end

  def format_price(price)
    number_to_currency(price, :unit => EURO_ENTITY, :format => "%u%n")
  end

  def plan_limit_box(label, value)
    text = value.nil? ? 'unlimited' : value.to_s
    html = %Q~
      <div class="plan-limit-label">#{label}</div>
      <div class="plan-limit-value">#{text}</div>
      <div style="clear: both;"></div>
    ~
  end
  
  def plan_limit_box_mb(label, value)
    text = value.nil? ? 'unlimited' : "#{value.to_s} MB"
    plan_limit_box(label, text)
  end
  
  def plan_limit_box_boolean(label, value)
    text = value ? 'enabled' : 'disabled'
    plan_limit_box(label, text)
  end

  def plan_mbytes_limit(mbytes_limit)
    if mbytes_limit
      "#{mbytes_limit} MB"
    else
      INFINITY_ENTITY
    end
  end
  
  def plan_button(plan, current_plan, not_available_plans)
    if current_plan
      if plan == current_plan
        return "It's Yours!"
      else
        if not_available_plans.keys.include?(plan)
          return "Plan too small"
        else
          operation_type = Domain.upgrading?(current_plan, plan) ? "upgrade" : "downgrade"
          unless Domain.current.can_change_plan_to?(plan)
            return "<span title='Downgrade will be allowed after the next billing period'>Can't downgrade!<span>"
          else
            return change_plan_form(plan, operation_type)
          end
        end
      end
    else
      return "<div class='signup-button'>#{link_to("", url_for(:action => :index, :controller => :register, :plan_name => plan.name))}</div>"
    end
  end

  def change_plan_form(plan, operation_type)
    html = ""
    html += form_tag(change_plan_admin_domain_path, :method => :put, :class => "change-plan-form #{'create-customer-first' if Domain.current && Domain.current.customer.dummy && plan.paid? } ")
    html += hidden_field_tag(:plan_id, plan.id)
    html += submit_tag(operation_type.camelize, :class => operation_type)
    html += "</form>"
  end

  def free_plan_link(free_plan, current_plan)
    if current_plan.nil?
      return link_to("Free plan", url_for(:action => :index, :controller => :register, :plan_name => free_plan.name))
    else
      return change_plan_form(free_plan, 'free plan')
    end
  end

  def plan_limit(limit)
    limit || INFINITY_ENTITY
  end

  def plan_flag(flag)
    flag ? 'enabled' : 'disabled'
  end

  def plan_header_for(plan)
    html =  <<-HTML
      <div class="plan-header">
        <div class="plan-name plan-name-#{plan.name.downcase}">#{plan.name}</div>
        <div class="plan-price">#{plan_price(plan.price)} /month </div>
      </div>
    HTML

    return html
  end
  
end

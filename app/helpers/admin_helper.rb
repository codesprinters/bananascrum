module AdminHelper

  def plan_chooser_helper(current_plan = nil)
    available_plans = Plan.enabled.public

    available_plans.map do |plan|
      plan_chooser_single_item(plan, current_plan == plan)
    end.join('')
  end

  def plan_chooser_single_item(plan, is_current = false)
    %Q!
      <h2><label>#{radio_button_tag('domain[plan_id]', plan.id, is_current, :class => 'checkbox')}#{h plan.name}</label></h2>
      <p>Users limit: #{h plan_limit_value(plan.users_limit)}</p>
      <p>Projects limit: #{h plan_limit_value(plan.projects_limit)}</p>
      <p>Storage limit: #{h plan_limit_value(plan.mbytes_limit)} megabytes</p>
    !
  end

  # returns the value numer or "No limit" string when the limit is not set
  def plan_limit_value(value)
    if value
      value.to_s
    else
      "No limit"
    end
  end

end

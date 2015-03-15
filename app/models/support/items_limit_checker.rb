class ItemsLimitChecker < LimitChecker
  def plan_limit
    @plan.items_limit
  end

  def instance_using(item)
    item.sprint_id ? 0 : 1
  end

  def domain_using(skipped_instance = nil)
    return 0 if @domain.new_record?

    where = "sprint_id IS NULL AND domain_id = :domain_id"
    if skipped_instance && !skipped_instance.new_record? then
      conditions = [where + " AND id != :id", { :domain_id => @domain.id, :id => skipped_instance.id }]
    else
      conditions = [where, { :domain_id => @domain.id }]
    end

    return Item.count(:conditions => conditions)
  end

  def error_message
    "Plan limit exceeded: too many items on backlog. " +
      "Consider upgrading your plan or removing some items."
  end
end
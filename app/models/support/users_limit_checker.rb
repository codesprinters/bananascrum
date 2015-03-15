class UsersLimitChecker < LimitChecker
  def plan_limit
    @plan.users_limit
  end

  def instance_using(user)
    if user.blocked? then 0 else 1 end
  end

  def domain_using(skipped_instance = nil)
    where = "domain_id = :domain_id AND blocked = 0"
    if skipped_instance && !skipped_instance.new_record? then
      conditions = [where + " AND id != :id", {:domain_id => @domain.id, :id => skipped_instance.id}]
    else
      conditions = [where, {:domain_id => @domain.id}]
    end
    User.count(:conditions => conditions)
  end

  def error_message
    "Plan limit exceeded: too many users. " +
      "Consider upgrading plan or blocking some users."
  end
end

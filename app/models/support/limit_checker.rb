class LimitChecker
  def initialize(domain, plan = nil)
    @domain = domain
    @plan = plan || domain.plan
  end

  def instance_within_plan?(instance)
    return unless @plan
    return true unless plan_limit
    instance_use = instance_using(instance)
    domain_use = domain_using(instance)
    return instance_use + domain_use <= plan_limit
  end

  def domain_within_plan?
    return unless @plan
    return true unless plan_limit
    domain_use = domain_using
    return domain_use <= plan_limit
  end

  # to override

  def plan_limit
    raise NotImplementedError
  end

  def instance_using(instance)
    raise NotImplementedError
  end

  def domain_using(skipped_instance = nil)
    raise NotImplementedError
  end

  def error_message
    raise NotImplementedError
  end
end

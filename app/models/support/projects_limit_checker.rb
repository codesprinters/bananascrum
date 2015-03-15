class ProjectsLimitChecker < LimitChecker
  def plan_limit
    @plan.projects_limit
  end

  def instance_using(project)
    if project.archived? then 0 else 1 end
  end

  def domain_using(skipped_instance = nil)
    where = "domain_id = :domain_id AND archived = 0"
    if skipped_instance && !skipped_instance.new_record?
      conditions = [where + " AND id != :id", {:domain_id => @domain.id, :id => skipped_instance.id}]
    else
      conditions = [where, {:domain_id => @domain.id}]
    end
    Project.count(:conditions => conditions)
  end

  def error_message
    "Plan limit exceeded: too many projects. " +
      "Consider upgrading plan or archiving some projects."
  end
end

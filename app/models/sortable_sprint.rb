class SortableSprint < SortableElements::Base
  def scope(attributes)
    "domain_id = #{attributes['domain_id']} AND sprint_id = #{attributes['sprint_id']} AND project_id = #{attributes['project_id']}"
  end

  def has_scope?(attributes)
    return !attributes['sprint_id'].nil? && !attributes['project_id'].nil?
  end

  def position_attribute
    "position_in_sprint"
  end
end

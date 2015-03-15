class SortableProductBacklog < SortableElements::Base
  def scope(attributes)
    "domain_id = #{attributes['domain_id']} AND sprint_id IS NULL AND project_id = #{attributes['project_id']}"
  end

  def has_scope?(attributes)
    return attributes['sprint_id'].nil? && !attributes['project_id'].nil?
  end

  def position_attribute
    "position"
  end
  
  def fix_order_with_planning_markers(project)
    current_scope = scope({'domain_id' => project.domain_id, 'project_id' => project.id })
    table_name = "`backlog_elements`"
    
    ActiveRecord::Base.connection.execute('SET @rownum := -1')
    sql = "UPDATE #{table_name}
      SET #{position_attribute} = @rownum := @rownum + 1 WHERE #{current_scope}
      ORDER BY ISNULL(#{position_attribute}),#{position_attribute} ASC,type = 'PlanningMarker' ASC"
    ActiveRecord::Base.connection.execute(sql, "Special fix ordering of #{table_name} (planning_markers)")
  end
  
end

class ProjectSweeper < ActionController::Caching::Sweeper
  observe Project

  def after_update(project)
    if project.backlog_unit_changed? || project.task_unit_changed?
      project.items.each do |item|
        expire_cache_for(item)
      end
    end
  end

  protected
  def expire_cache_for(item)
    expire_fragment :id => item.id, :controller => '/items', :action => :show, :project_id => item.project.name, :action_suffix => :old
    expire_fragment :id => item.id, :controller => '/items', :action => :show, :project_id => item.project.name, :action_suffix => :new
  end
  

end
  

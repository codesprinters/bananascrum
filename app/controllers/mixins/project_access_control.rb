# This module provides finding the current project and
# checking access to it
module ProjectAccessControl
  def self.included(base)
    base.extend ProjectAccessControlClassMethods 
  end
  
  # Finds current project. A template method, can be overwritten in subclases
  def find_current_project
    if params[:project_id] then
      return Domain.current.projects.find_by_name(params[:project_id])
    else
      return nil
    end
  end
  
  #
  # Sets up Project.current. Uses find_current_project to determine current project
  #
  def set_current_project
    begin
      Project.current = self.find_current_project
      Time.zone = Project.current.time_zone
      
      user = User.current
      if user && user.active_project != Project.current
        user.update_attribute(:active_project_id, Project.current.id)
      end
    rescue => e
      Project.current = nil
    end
  ensure
    @current_project = Project.current
    yield
    Project.current = nil
  end

  #
  # Returns 404 if current project is not set
  #
  def ensure_current_project_set
    active_project = Project.current
    user = User.current
    # either no project or user not allowed to access this project
    if active_project.nil? || (user && !user.projects.include?(active_project))
      flash[:warning] = "Select active project"
      if request.xhr?
        render_json 404, :_error => { :type => 'set_current_project', :message => 'No active project chosen' }
      else
        redirect_to projects_url
      end
    else
      yield
    end
  end
  
  # Non-GET requests should be blocked for archived projects
  def disallow_non_get_for_archived_projects
    if Project.current && Project.current.archived? && request.method != :get then
      if !self.class.actions_allowed_for_archived_projects.include?(action_name.to_sym)
        error_message =  "This action is not allowed for archived projects"
        if request.xhr? then
          render_json 403, :_error => { :type => 'non_get_on_archived_project',
                                        :message => error_message }
        else
          begin
            flash[:error] = error_message
            redirect_to :back
          rescue ActionController::RedirectBackError
            render :template => 'shared/archived_project', :status => 403
          end
        end
      end
    end
  end

  def sprint_edition_forbidden?(sprint)
    request.method != :get && !sprint.nil? && !sprint.can_be_edited_by?(User.current)
  end

  def forbid_non_get_for_finished_sprint
    flash[:error] = "Only admin can edit finished sprint of this project"
    respond_to do |format|
      format.html do
        begin
          return redirect_to :back
        rescue
          render :template => 'shared/finished_sprint', :status => 403
        end
      end
      format.js do
        return render_json(403, { :_error => { :message => flash[:error] } })
      end
    end
  end

  def disallow_non_get_for_finished_sprints
    if self.sprint_edition_forbidden?(@sprint)
      return self.forbid_non_get_for_finished_sprint
    else
      false
    end
  end

  module ProjectAccessControlClassMethods
    def allow_for_archived_projects(*methods)
      @allowed_for_archived_projects ||= Set.new
      @allowed_for_archived_projects += methods
    end

    def actions_allowed_for_archived_projects
      @allowed_for_archived_projects || Set.new
    end
  end
  
end

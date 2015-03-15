class Admin::ProjectsController < AdminBaseController
  include InPlaceEditing

  include ApplicationHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::TagHelper
  helper :users, :admin
  
  before_filter :set_project, :except => [ :create, :new ]
  before_filter :redirect_if_not_xhr, :only => [:new, :create, :edit, :reset_settings_to_default, :update]

  cache_sweeper :project_sweeper, :only => [:update]
  prepend_after_filter :refresh_projects, :only => [:archive, :destroy, :create]

  def edit
    @assigned_users = @project.nil? ? [] : @project.users
    @codename_opts = {:disabled => "disabled"}
    render_to_json_envelope({:layout => false}, graphs_hashes_for_select_checkbox)
  end

  def update
    if params["visible-graphs"] == "None"
      @project.visible_graphs = Project::visible_graphs_unselected
    end
    if @project.update_attributes(params[:project])
      flash[:notice] = "Project was successfully updated."
      return render_to_json_envelope :partial => "admin/projects/projects_list", :locals => {:projects => User.current.projects}
    else
      @assigned_users = @project.nil? ? [] : @project.users
      render_json 409, :_error => { :message => @project.errors.full_messages.join }
    end
  end

  def new
    @project = Project.new
    @project.domain = Domain.current
    @project.free_days = {'6' => '1', '0' => '1'}
    render_to_json_envelope({:layout => false}, graphs_hashes_for_select_checkbox.merge(mass_assignment_hashes))
  end

  def create
    @project = Project.new(params[:project])
    @project.domain = Domain.current

    if @project.save
      flash[:notice] = "New project created. Start using it with creating some backlog items"

      # deliver notifications
      @project.users.each do |user|
        Notifier.deliver_roles_assigment(@project, user) if user.like_spam?
      end

      return render_to_json_envelope :partial => "project", :object => @project
    else
      return render_json 409, {:html => render_to_string(:action => :new, :layout => false)}.merge(graphs_hashes_for_select_checkbox).merge(mass_assignment_hashes)
    end
  end

  def destroy
    begin
      @project.purge!
      flash[:notice] = "Project “#{@project.name}” was successfully deleted"
      return render_json :ok
    rescue Project::DestroyError => de
      logger.error "Failed to delete project: '#{@project.name}': #{de.message}"
      flash[:error] = "Project “#{@project.name}” can't be deleted!"
    rescue => e
      raise e # Rethrow exception
    end
    render_json 409, :_error => { :message => flash[:error] }
  end

  def project_description_text
    if @project.description.nil?
      render :text => "Project description not set"
    else
      render :text => @project.description
    end
  end

  def reset_settings_to_defaults
    @project.reset_settings!
    flash[:notice] = "Settings reset for project #{@project.presentation_name}"
    render_to_json_envelope :partial => "settings_form", :leaveOpen => true 
  rescue Project::ProjectError => e
    render_json 409, :_error => { :message => e.message, :type => 'project_error' }
  end
  
  def archive
    @project.archived = params[:project_archived].to_i != 0
    @project.save!
    if @project.archived
      flash[:notice] = "Project #{@project.name} archived"
    else
      flash[:notice] = "Project #{@project.name} unarchived"
    end
    render_json 200, { :project => @project.id, :archived => @project.archived }
  rescue ActiveRecord::RecordInvalid => ri
    flash[:error] = ri.message
    render_json 409, {:project => @project.id}
  end

  protected

  def graphs_hashes_for_select_checkbox
    all_graphs = Project::DEFAULT_VISIBLE_GRAPHS.map {|key, value| {:label => key.to_s, :value => 1, :name => "project[visible_graphs][#{key.to_s}]" }}
    selected_graphs = @project.selected_visible_graphs_keys
    return {:all_graphs => all_graphs, :selected_graphs => selected_graphs}
  end
  
  def mass_assignment_hashes
    list = {}
    users = @project.domain.users.not_blocked
    roles = Role.find(:all)
    
    roles.each do |role|
      list[role.code] = users.map { |user| { :label => user.login, :value => 1, :name => "project[users_to_assign][#{role.code}][#{user.login}]"} }
    end
    
    selected = {}
    roles.each { |role| selected[role.code] = [] }
    if @project.users_to_assign
      selected = @project.users_to_assign.inject({}) do |new_hash, (k,v)|
        new_hash[k] = v.keys 
        new_hash
      end
    end
    
    return { :mass_assignment => list, :mass_assignment_selected => selected }
  end
  
  def refresh_projects
    return if error?
    
    append_to_envelope(:_projects, projects_for_select)
  end

  def set_project
    @project = find_current_project or render_not_found
  end
  
  def find_current_project
    if params[:id] then
      User.current.projects.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound.new 'Project id not specified'
    end
  end
end

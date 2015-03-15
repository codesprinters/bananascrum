class Admin::UsersController < AdminBaseController
  include UsersHelper
  
  helper :users, :admin

  prepend_after_filter :refresh_project_members, :only => [ :create ]

  def index
    prepare_users
  end

  verify :method => [:post, :delete], :only => ["grant_admin_rights", "revoke_admin_rights"],
    :redirect_to => {:action => 'list'}
  verify :method => [:put], :only => ["block", "admin"]

  before_filter :get_user_for_editing, :only => [ :block, :admin ]
  before_filter :redirect_if_not_xhr, :only => [ :new, :create, :edit, :destroy ]

  def new
    get_projects_and_roles
    @form = form_class.new
    @user = @form.user
    render_to_json_envelope({ :layout => false }, { :projects_list => project_assignment_hash(@user, @projects) })
  end

  def create
    @form = form_class.new(params[:form])
    @user = @form.user
     
    @user.active = true
    @user.domain = Domain.current
    
    if @form.save
      @user_activation = @user.user_activations.create(:reset_pwd => true)
      @user_activation.save!

      if @user.role_assignments.blank? 
        flash[:notice] = "User “#{@user.login}” was created with no assigned project." 
      else
        flash[:notice] = "User “#{@user.login}” was successfully created."
        @project = @user.active_project = @user.role_assignments.first.project # @project is used to refresh team members quantity
        @user.save
      end

      if !params[:add_note_checkbox]
        @user.note_for_user = nil
      end
      
      if AppConfig.send_emails
        Notifier.deliver_new_user(@user, @user_activation.key)
      end
      
      return render_to_json_envelope({:partial => "user", :object => @user})
    else
      get_projects_and_roles
      
      projects_to_assign = @form.projects_to_assign && Domain.current.projects.find_by_id(@form.projects_to_assign).presentation_name
      return render_json 409, :html => render_to_string(:action => :new, :layout => false), :projects_list => project_assignment_hash(@user, @projects), :select_projects => projects_to_assign
    end

  end

  def edit
    @user = Domain.current.users.find(params[:id])
    @assigned_projects = @user.assigned_projects
    return render_to_json_envelope
  end
  
  def update
    @user = Domain.current.users.find(params[:id])
    @user.login = params[:user][:login] unless params[:user][:login].nil? # attr protected
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      return render_to_json_envelope :partial => "user", :object => @user
    else
      @assigned_projects = @user.projects
      return render_json 409, :html => render_to_string(:action => 'edit', :layout => false)
    end
  end

  def destroy
    user = Domain.current.users.find(params[:id])
    project_list = user.projects.map { |project| { :id => project.id, :members => project.users.count - 1} }
    if user.destroy
      render_json :ok, :_project_members => project_list
    else
      unless user.errors.blank?
        render_json 409, :_error => { :message => user.errors.full_messages.join("\n") }
      else
        flash[:persistant] = "You can't delete this user but you can block him. Blocked users are ignored by the plan limits "
        render_json 409
      end
    end
  end

  def admin
    @user.admin = params[:user_admin].to_i != 0
    @user.save!
    if @user.admin?
      flash[:notice] = "Admin rights have been granted to user #{@user.login}"
    else
      flash[:notice] = "Admin rights have been revoked from user #{@user.login}"
    end
    render_user_properties @user
  end

  def block
    @user.blocked = params[:user_blocked].to_i != 0
    @user.save!
    if @user.blocked then
      flash[:notice] = "User account #{@user.login} was successfully blocked."
    else
      flash[:notice] = "User account #{@user.login} was successfully unblocked."
    end
    render_user_properties @user
  end
  
  protected
  def form_class
    AppConfig.send_emails ? UserForm : UserFormWithPasswordAssignment
  end


  def get_projects_and_roles
    @projects = Domain.current.projects.not_archived
    @roles = Role.find(:all)
  end

  def get_user_for_editing
    return render_json 403 unless User.current.admin?
    @user = Domain.current.users.find(params[:id])
    if @user.nil?
      flash[:error] = "User not found"
      return render_json 404
    end
    if @user == User.current then
      flash[:error] = "You cannot modify yourself!"
      return render_json 400
    end

  end

  def render_user_properties(user)
    render_json 200, :user => user.id, :blocked => user.blocked?, :admin => user.admin?
  end
  
end

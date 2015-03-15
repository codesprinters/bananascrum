class Admin::RoleAssignmentsController < AdminBaseController
  before_filter :find_project
  before_filter :redirect_if_not_xhr
  prepend_after_filter :refresh_project_members

  def create
    @user = Domain.current.users.find(params[:user_id])
    @role = Role.find(params[:role_id])

    # check if user has this role in project already
    if @project && @project.get_user_roles(@user).include?(@role)
      flash[:warning] = "User has #{@role.name} role in this project."
    else
      # assign new user with selected role to project
      if @project && @project.add_user_with_role(@user, @role)
        flash[:notice] = "User #{@user.login} assigned to project #{@project.name} as #{@role.name}."
        Notifier.deliver_roles_assigment(@project, @user, @role) if @user.like_spam?
      else
        flash[:error] = "Unable to assign #{@user.login} to this project."
        return render_json 409
      end
    end

    render_roles_list

  end

  def destroy
    @assignment = @project.role_assignments.find(params[:id])
    @user = @assignment.user
    if @assignment.destroy then
      flash[:notice] = "User #{@assignment.user.login} was unassigned from #{@project.name} project as #{@assignment.role.name}."
      Notifier.deliver_role_withdrawal(@project, @user, @assignment.role) if @user.like_spam?
    else
      flash[:warning] = "Unable to unassign user #{@assignment.user.login} from #{@project.name} project."
      return render_json 409
    end

    render_roles_list

  end

  protected

  def render_roles_list
    @assigned_projects = @user.assigned_projects.reload
    @assigned_users = @project.nil? ? [] : @project.users.reload
    return render_json 200,
      :roles => render_to_string(:partial => "admin/users/projects"),
      :roles_for_project => render_to_string(:partial => "admin/projects/roles"),
      :leaveOpen => true
  end
 
  def find_project
    @project = User.current.projects.find_by_name(params[:project_id]) || Domain.current.projects.find(params[:project_id])
  end

end

  class SessionsController < DomainBaseController
  protect_from_forgery :except => 'create'
  before_filter :set_user_to_nil, :only => [:create, :new]
  skip_filter :authorize, :only => [:create, :new]
  skip_filter :handle_ssl, :only => [:create, :new]
  before_filter :redirect_to_https_protocol_if_enabled, :only => [:new, :create]

  def new
    response.headers["Cache-Control"] = 'no-cache'
    user = nil
    unless session[:user_id].nil?
      user = User.find_by_id(session[:user_id])
    end
    return smart_redirect_for_user(user) unless user.nil?

    @current_menu_item = "Login"
    if Domain.current.name == AppConfig.demo_domain
      flash[:persistant] = "Please login as 'admin' with password 'password'"
    end

    render :layout => layout_for_current_user
  end

  def create
    session[:user_id] = nil
    user = User.authenticate(params[:login], params[:password])

    if (user.nil? or user.login != params[:login])
      flash[:error] = "Login failed"
      redirect_to(new_session_url) and return
    end

    if (not user.active?)
      flash[:error] =  "You must activate your account first"
      redirect_to(new_session_url) and return
    end

    if user.blocked?
      flash[:error] = "Your account has been blocked. Please contact your domain administrator"
      redirect_to(new_session_url) and return
    end
    
    session[:user_id] = user.id
    flash[:notice] = "Logged in successfully"

    # :first time is used in sprint controller to display (only once, after login)
    # flash with info where user was redirected
    session[:first_time] = true

    user.last_login = Time.current
    user.save
    smart_redirect_for_user(user)
  end

  def destroy
    if session[:user_id]
      reset_session
      flash[:notice] = "You have been logged out."
      User.current = nil
      return redirect_to(new_session_url)
    end
  end

  def redirect_to_active_project
    @user = User.current
    smart_redirect_for_user(@user)
  end

  def smart_redirect_for_user(user)
    unless session[:return_to]
      project = user.active_project
      if project
        roles = project.get_user_roles(user)
        if roles.any? {|role| role.name == "Product Owner"}
          redirect_to(project_items_path(user.active_project))
        else
          redirect_to_project_last_sprint(user.active_project)
        end
      else
        redirect_to(projects_url)
      end
    else
      redirect_to(session[:return_to])
      session[:return_to] = nil
    end
  end

  def redirect_to_project_last_sprint(project)
    sprint = project.last_sprint
    if sprint
      redirect_to(project_sprint_path(project, sprint))
    else
      redirect_to(project_sprints_path(project))
    end
  end

end

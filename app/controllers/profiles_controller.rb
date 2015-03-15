class ProfilesController < DomainBaseController
  before_filter :find_user, :only => [ :edit, :update ]
  
  def logout
    if session[:user_id]
      reset_session
      flash[:notice] = "You have been logged out"
      User.current = nil
      return redirect_to(new_session_url)
    end
  end

  def edit
  end

  def update
    # Admin can change his login, attr protected
    if @user.admin?
      @user.login = params[:user][:login] if params[:user][:login]
    end

    # ugly 2 liner because we don't have a record for the old theme
    theme_id = params[:user][:theme_id]
    params[:user][:theme_id] = theme_id == "0" ? nil : theme_id
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Your profile was successfully updated.'
    end
    return redirect_to :action => :edit
  end

  protected

  def find_user
    @user = User.current
    # preload user's theme
    @theme_name = @user.theme.nil? ? "Old" : @user.theme.name
  end

end

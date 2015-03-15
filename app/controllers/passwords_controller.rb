class PasswordsController < DomainBaseController
  include FindActivation

  before_filter :find_activation, :only => [:new, :create]
  # User will be authorized with UserActivation
  before_filter :set_user_to_nil, :only => [:new, :create, :forgot, :reset]
  skip_filter :authorize, :only => [:new, :create, :forgot, :reset]

  def forgot
  end

  def reset
    @user = Domain.current.users.find_by_login(params[:login])
    if @user.nil? || !@user.active?
      flash[:error] = "Unknown login"
      render :action => :forgot, :status => :conflict
    elsif @user.blocked?
      flash[:error] = "User account #{@user.login} is blocked. Contact your domain admin."
      render :action => :forgot, :status => :conflict
    else
      @user.reset_password
      flash[:notice] = "Activation link to reset password sent to email."
      redirect_to(new_session_url)
    end
  end


  def new
    @user = @activation.user || User.new
  end
  
  def create
    @user = @activation.user
    if @user.nil?
      flash[:error] = "Invalid activation code. Please make sure you have pasted it correctly."
      return render :action => "new"
    end

    fill_users_password
    if @user.valid?
      use_activation
      flash[:notice] = 'Password updated successfully. Please log in.'
      return redirect_to(new_session_url)
    else
      render :action => "new" and return
    end
  end
  
  def edit
  end

  def update
    @user = User.current
    if User.authenticate(@user.login, params[:user][:old_password])
      fill_users_password
      if @user && @user.valid?
        @user.save!
        flash[:notice] = 'Password updated successfully.'
        return redirect_to edit_profile_path
      end
    else
      @user.errors.add(:old_password, "is incorrect")
    end

    flash[:error] = 'Password update failed.'
    render :action => "edit"
  end

  private

  def fill_users_password
    if @user
      @user.user_password = params[:user][:user_password]
      @user.user_password_confirmation = params[:user][:user_password_confirmation]
    end
  end

  def use_activation
    User.transaction do
      @user.save!
      @activation.destroy
    end
  end

end

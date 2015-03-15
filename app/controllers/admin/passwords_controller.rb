class Admin::PasswordsController < AdminBaseController
  before_filter :find_user

  def reset
    password = User.generate_password
    @user.user_password = password
    @user.save!

    @user_activation = @user.user_activations.create(:reset_pwd => true)
    @user_activation.save!

    Notifier.deliver_admin_reset_password(@user, @user_activation.key)
    flash[:notice] = "Password resetted and sent over to user"
    render_json :ok
  end

  def new
    render_to_json_envelope
  end
  
  def create
    @user.user_password = params[:user] && params[:user][:user_password]
    @user.user_password_confirmation = params[:user] && params[:user][:user_password_confirmation]
    @user.password_changed = true
    if @user.save
      flash[:notice] = "Password updated"
      render_json :ok
    else
      form = render_to_string(:action => :new, :layout => false)
      render_json 409, { :html => form }
    end
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end
end

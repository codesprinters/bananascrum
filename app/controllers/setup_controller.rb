class SetupController < ApplicationController
  before_filter :check_if_admin_exists, :only => :first_admin
  skip_before_filter :check_license_key, :only => :change_license
  skip_before_filter :check_first_admin, :only => :first_admin

  def first_admin
    @admin = get_admin
    if request.post?
      @admin.attributes = params[:admin]
      @admin.login = params[:admin][:login]
      @admin.active = true
      @admin.user_password = params[:admin][:user_password]
      @admin.user_password_confirmation = params[:admin][:user_password_confirmation]
      @admin.theme = Theme.first

      if @admin.valid? && DomainChecks.disable { @admin.save }
        flash[:notice] = "Setup was completed"
        redirect_to(admin_panel_path)
      end
    end
  end

  def change_license
    @license = get_license
    if !@license.new_record? && @license.valid?
      return redirect_to(root_path) 
    end

    if request.post?
      @license.attributes = params[:license]

      # set license valid_to field
      @license.valid_to = @license.rsa_key.valid_to

      if @license.valid? && DomainChecks.disable { @license.save }
        flash[:notice] = "License information updated"
        redirect_to(admin_panel_path)
      end
    end
  end

  protected
  
  def get_admin
    Domain.current = Domain.default
    if Domain.current.users.admins.empty?
      Admin.new(:domain => Domain.current)
    else
      Domain.current.users.admins.first
    end
  end

  def get_license
    Domain.current = Domain.default
    if Domain.current.license
      Domain.current.license
    else
      License.new(:domain => Domain.current)
    end
  end

  def check_if_admin_exists
    redirect_to(admin_panel_path) unless Domain.default.users.admins.empty?
  end

end

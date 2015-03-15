# This module provides domain detection (and setting up Domain.current)
# as well as authentication. It is automatically included in DomainBaseController
module DomainAndAuthorization
  
  def self.included(base)
    base.around_filter :set_current_domain
    base.before_filter :check_license_key
    base.before_filter :check_first_admin
    base.around_filter :authorize
    base.after_filter :set_user_to_nil
    base.after_filter :set_domain_to_nil
  end
  
  # Sets up Domain.current
  # Redirects to registation if needed
  def set_current_domain
    begin
      domain = Domain.default
      raise ActiveRecord::RecordNotFound unless domain
      Domain.current = domain 
      yield
    rescue SecurityError
      render_error_page 403, 'Access denied', e.to_s
    end
  end  
  
  def set_domain_to_nil
    Domain.current = nil
  end
  
  # Finds the current user.
  # Redirects to login if needed.
  def authorize
    User.current = nil # clean up from previous request, just in case thread is re-used
    user = User.find_by_id(session[:user_id])

    if user.nil? || user.blocked? then
      flash[:notice] = "Please log in"
      session[:return_to] = request.request_uri
      redirect_to(login_url)
    else
      User.current = user
      yield
    end
  end

  def set_user_to_nil
    User.current = nil # clean up 
  end

  def handle_ssl
    if AppConfig.ssl_enabled && Domain.current
      redirect_to_suitable_protocol
    else
      redirect_to :protocol => "http://" if secure_connection?
    end
  end

  def redirect_to_suitable_protocol
    if redirect_to_https?
      redirect_to :protocol => "https://"
    elsif redirect_to_http?
      redirect_to :protocol => "http://"
    end
  end

  def redirect_to_https?
    Domain.current.plan.ssl? and !secure_connection?
  end

  def redirect_to_http?
    !Domain.current.plan.ssl? and secure_connection?
  end

  def check_license_key
    unless (Domain.current && Domain.current.license && Domain.current.license.has_valid_key?)
      return redirect_to(change_license_path)
    end
  end

  def check_first_admin
    if (Domain.current && Domain.current.users.admins.empty?)
      return redirect_to(register_first_admin_path)
    end
  end

end

class ApplicationController < ActionController::Base
  filter_parameter_logging :password, :password_confirmation

  layout :layout_for_current_user

  JSON = ActiveSupport::JSON

  # Mixin simple access control class methods
  extend LimitAccess

  # Notify about exceptions using email
  include ExceptionNotifiable
  include CommonResponses
  include ErrorResponses
  include EnvelopeAfterfilters
  include ExceptionFilters
  
  class << self
    alias_method :standard_exceptions_to_treat_as_404, :exceptions_to_treat_as_404
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '<%= app_secret %>'

  protected

  def new_layout_only
    unless User.current.new_layout
      render_error_page(404, "New layout only", "We are sorry. This section is available only in new layout. You can switch it in your <a href='#{edit_profile_path}'>profile</a>")
    end
  end

  def secure_connection?
    request.ssl? or request.headers["X-Forwarded-Proto"].to_s.downcase == 'https'
  end
  
  def juggernaut_broadcast
    return if error?
    return if request.get?
    envelope = nil
    
    begin
      envelope = JSON.decode(response.body)
    rescue JSON::ParseError
      envelope = { :html => response.body }
      envelope[:item] = @item.id if @item
    end
      
    operation = "#{params[:controller]}/#{params[:action]}"
    
    message = { 
      :operation => operation,
      :envelope => envelope,
      :session_id => params[:session_id] # this is used to ignore messages about updates in client who triggered broadcast
    }
    
    JuggernautCache.instance.broadcast(message, [@current_project.id])
  rescue Errno::ECONNREFUSED
    logger.error("Connecting with Juggernaut failed!")
  end

  def layout_for_current_user
    (User.current.nil? || User.current.new_layout) ? 'new_layout' : 'application'
  end

  protected

  def secure_connection?
    request.ssl? or request.headers["X-Forwarded-Proto"].to_s.downcase == 'https'
  end

  # Renders one from two given partials depending on which layout user has selected
  def conditional_render(partial_new, partial_old)
    if layout_for_current_user == 'new_layout'
      render partial_new
    else
      render partial_old
    end
  end

end

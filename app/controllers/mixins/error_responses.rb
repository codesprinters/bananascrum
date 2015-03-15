# This module contains methods for rendering default HTTP responses
# Used in ApplicationController.
module ErrorResponses
  JSON = ActiveSupport::JSON
 

  # exception handler for invalid authenticity token
  def handle_invalid_authenticity_token
    status = 403
    message = "Your session has expired. Please login again."
    if request.xhr? # Set proper error type for auth token
      render_json status, :_error => { :type => 'authenticity_token', :message => message }
    else
      render_error_page status, 'Forbidden', message
    end
  end

  # Renders Not found error page with HTTP status 404
  def render_not_found
    if request.xhr?
      render_error_page 404, 'Not found', "Sorry, but we couldn't find the page you're looking for."
    else
      render(:template => '404.html', :layout => false, :status => 404)
    end
  end

  # Exception handler for ActionController::MethodNotAllowed
  def render_method_not_allowed(method_not_allowed)
    method_not_allowed.handle_response!(response)
    render_error_page 405, 'Method Not Allowed', 'Method Not Allowed'
  end

  # Helper method for rendering error page
  # It supports both html and JSON format
  def render_error_page(status, title, message, options = {})
    if request.xhr?
      render_json status, :_error => { :type => title.downcase.gsub(' ', '_'), :message => message}
    else
      @title = title
      @message = message
      render(options.merge({ :partial => 'error/error_page', :layout => 'new_layout', :status => status.to_i }))
    end
  end

end

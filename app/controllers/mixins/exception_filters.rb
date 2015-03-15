# Used in Application Controller
module ExceptionFilters

  def self.included(base)
    # Handle InvalidAuthenticityToken exception
    base.rescue_from ActionController::InvalidAuthenticityToken, :with => :handle_invalid_authenticity_token
    # We can handle 404 type of errors better
     # TODO: Do the same for ActionController::UnknownAction?
    base.rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError, :with => :render_not_found
    # Provide same error page for method not allowed
    base.rescue_from ActionController::MethodNotAllowed, :with => :render_method_not_allowed
  end
end

# This module contains methods for rendering default HTTP responses
# Used in ApplicationController.
module CommonResponses
  JSON = ActiveSupport::JSON
  
  def get_domain_name
    # Hack to make selenium and intergration tests work with subdomains
    if RAILS_ENV == "test"
      if params[:_domain]
        cookies['domain'] = params[:_domain]
        return params[:_domain]
      elsif cookies['domain']
        return cookies['domain']
      end
    end
    # End of hack

    if request.host.ends_with?("." + AppConfig.banana_domain)
      return request.host.chomp("." + AppConfig.banana_domain)
    else
      return ""
    end
  end

  def redirect_if_not_admin
    unless User.current.admin?
      flash[:warning] = "You don't have permissions to do that, sorry."
      redirect_to edit_profile_url
    end
  end

  # Render wrappers

  # Renders JSON envelope with given status
  # Adds flashes to envelope, which are displayed in browser
  def render_json(status, envelope = {})
    envelope[:_sprint_id] = @sprint.id if @sprint
    store_flashes!(envelope)
    render(:status => status, :json => envelope)
  end

  def render_to_json_envelope(options = {}, envelope = {})
    html = render_to_string(options)

    if options.has_key?(:partial)     # hack to render both new and old partials. New partial should end with _new.html.erb
      begin
        new_html = render_to_string(options.merge({:partial => options[:partial] + "_new"}))
      rescue ActionView::MissingTemplate => e
        envelope[:html] = html
      else
        envelope[:html] = {
          :old => html,
          :new => new_html
        }
      end
    else
      envelope[:html] = html
    end

    render_json(:ok, envelope)
  end

  # This method is used in rare cases, when we send JSON as non-ajax
  # We have to set Content-Type header to text/plain. Otherwise Firefox would
  # want to download content with application/json MIME type
  #
  # Usually this method should be used to send data to AjaxUpload plugin and
  # decoded on client side. In other cases, render_json should be sufficient.
  def render_json_as_plain_text(status, envelope = {})
    store_flashes!(envelope)
    response.headers["Content-Type"] = 'text/plain; charset=utf-8'
    render :text => ActiveSupport::JSON.encode(envelope), :status => status, :layout => false
  end

  def redirect_to_https_protocol_if_enabled
    if AppConfig.ssl_enabled and !secure_connection?
      redirect_to :protocol => "https://", :params => params
    elsif !AppConfig.ssl_enabled and secure_connection?
      redirect_to :protocol => "http://", :params => params
    end
  end

  # Modifies envelope, so it'll contain :_flashes key, if there are some flash
  # messages set
  def store_flashes!(envelope)
    unless flash.empty?
      # Flashes are weird, so this assignment is neccessary
      flashes  = flash
      envelope[:_flashes] = {}
      flashes.each do |k,v|
        envelope[:_flashes][k] = CGI::escapeHTML v
      end
    end
    envelope
    flash.sweep
  end

end

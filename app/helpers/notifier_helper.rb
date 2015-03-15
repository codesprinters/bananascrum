module NotifierHelper
  def mail_footer(locals = {})
    locals.reverse_merge!({:display_spam_info => false, :user => nil})
    render :partial => "/notifier/footer", :locals => locals
  end
  
  def activation_link(user, key = nil)
    url_params = {
      :controller => 'profiles', 
      :action => 'activate', 
      :host => "#{@user.domain.name}.#{::AppConfig.banana_domain}", 
      :protocol => protocol_for_user(user),
      :only_path => false
    }
    url_params[:key] = key if key
    return url_for(url_params)
  end
  
  def protocol_for_user(user)
    return user.domain.plan.ssl ? 'https' : 'http'
  end
end

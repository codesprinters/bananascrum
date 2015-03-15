module JuggernautTagHelper
  def synchronization_scripts(options = {})
    result = []
#     if RAILS_ENV != "production"
#       result << javascript_include_tag('http://getfirebug.com/releases/lite/1.2/firebug-lite-compressed.js')
#     end
    result << juggernaut(options)
    result << javascript_tag("bs.mutex.init();")
    result.join("\n    ")
  end

  def juggernaut_tag
    return unless AppConfig::livesync_enabled
    synchronization_scripts({
      :client_id => @juggernaut_session.id,
      :session_id => @juggernaut_session.id,
      :channels => [@current_project.id]
    })
  end
end

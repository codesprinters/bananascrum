require 'juggernaut_message'

class JuggernautCache
  include Singleton
  
  def initialize
    Rails.cache.write('juggernaut_message_id', 0) unless current_id
  end
  
  def current_id
    resp = Rails.cache.read('juggernaut_message_id')
    unless resp
      Rails.cache.write('juggernaut_message_id', 0)
      return 0
    else
      return resp
    end
  end
  
  def next_id
    response = current_id
    Rails.cache.write('juggernaut_message_id', response + 1)
    return response
  end
  
  def get_scheduled_messages(juggernaut_session)
    response = []
    juggernaut_session.initial_message_id.upto(self.current_id) do |index|
      message = Rails.cache.read("message_" + index.to_s)
      if message && message.channels.include?(juggernaut_session.project_id)
        response << message
      end
    end
    return response
  end
  
  def broadcast(body, channels)
    begin
      Juggernaut.send_to_channels(body, channels)
    rescue Errno::ECONNREFUSED
      Rails.logger.error("Connecting with Juggernaut failed!")
    end
    
    Rails.cache.write("message_" + next_id.to_s, JuggernautMessage.new(body, channels), :expires_in => 10.seconds)
  end
end
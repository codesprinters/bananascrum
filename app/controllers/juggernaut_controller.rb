# Controller responsible for handling Juggernaut requests
# and restricting access to certain operations.
#
# Remember to block access to methods subscribe disconnected and logged_out
# for anyone except juggernaut server (usually he call from localhost)
# in htaccess or using before filter
#
# Keep in mind that due to Juggernaut intristics, session_id was made same as
# client_id and they are id of JuggernautSession.
#
# Actions should render nothing - Juggernaut care only of HTTP status code
#
class JuggernautController < ApplicationController
  before_filter :find_session
  skip_before_filter :verify_authenticity_token
  
  prepend_after_filter :broadcast_connected_users

  # Called by Juggernaut everytime a client subscribes.
  # Parameters passed are: session_id, client_id and an array of channels.
  def subscribe
    @juggernaut_session.subscribed
    locks = channel.items.locked
    unless params[:channels].length == 1 && params[:channels].first.to_i == channel.id 
      return render :status => :conflict, :nothing => true
    end
    locks_ids = locks.map(&:id)
    payload = {
      :envelope => { :locks => locks_ids, :logged_users => connected_users.join(', ') },
      :operation => 'current_locks'
    }
    messages = [payload]
    messages += JuggernautCache.instance.get_scheduled_messages(@juggernaut_session).map(&:body)

    render :status => 200, :text => messages.to_json
  end

  # Called everytime a specific connection from a subscribed client disconnects.
  # Parameters passed are session_id, client_id and an array of channels specific to that connection.
  def disconnected
    @juggernaut_session.remove_all_locks
    index = connected_users.index(@juggernaut_session.user.full_name)
    connected_users.delete_at(index) if index
    render :nothing => true
  end

  # Called when all connections from a subscribed client are closed.
  # Parameters passed are session_id and client_id.
  def logged_out
    @juggernaut_session.destroy
    render :nothing => true
  end


  private
  
  def broadcast_connected_users
    message = { 
      :operation => "connected_users",
      :envelope => {
        :logged_users => connected_users.join(', ')
      },
      :session_id => @juggernaut_session.id
    }
    
    ids_to_send = clients_in_channel 
    ids_to_send.delete(@juggernaut_session.id) #this is to prevent sending to newly subscribed user
    unless ids_to_send.blank?
      Juggernaut.send_to_clients(message, ids_to_send)
    end
  rescue Errno::ECONNREFUSED
    logger.error("Connecting with Juggernaut failed!")
  end
  
  def clients_in_channel 
    ((params[:clients_in_channel] && params[:clients_in_channel].values) || []).map(&:to_i)
  end
  
  def connected_users
    return @connected_users if @connected_users
    
    @connected_users = clients_in_channel.map do |session_id|
      j_s = @juggernaut_session.project.juggernaut_sessions.logged_in.find_by_id(session_id)
      j_s.user.full_name if j_s
    end
    return @connected_users
  end

  def find_session
    DomainChecks.disable do
      @juggernaut_session = JuggernautSession.find(session_id)
      Domain.current = @juggernaut_session.domain
    end
    @juggernaut_session
  end

  def channel
    @juggernaut_session.project
  end

  def session_id
    params[:session_id].to_i
  end

  # this should be same as session_id
  def client_id
    params[:client_id].to_i
  end

end

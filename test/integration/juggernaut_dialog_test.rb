require File.dirname(__FILE__) + '/../test_helper'

require 'webrick'



$: << File.join(RAILS_ROOT, 'vendor', 'gems', 'json-1.1.3', 'lib')
$: << File.join(RAILS_ROOT, 'vendor', 'gems', 'eventmachine-0.12.11-java', 'lib')
$: << File.join(RAILS_ROOT, 'vendor', 'gems', 'eventmachine-0.12.11-java', 'ext')

require File.join(RAILS_ROOT, 'vendor', 'gems', 'juggernaut-0.5.8', 'lib', 'juggernaut')

class CSTimeout
  def self.timeout(sec, &block)
    resp = nil
    thread = Thread.new do
      resp = block.call
    end
    
    expired = thread.join(sec).nil?
    
    if expired
      thread.terminate
      raise TimeoutError.new
    end
    
    return resp
  end
end

class JuggernautController
  def rescue_action(e); raise e; end 
end

class JuggernautDialogTest < ActionController::IntegrationTest 
  CR = "\0"
  HOST = Juggernaut.send(:hosts).first

  fixtures :all

  def setup
    path = '/opt/jruby/bin:' + ENV['PATH']
    argv = ['jruby', File.join(RAILS_ROOT, 'lib', 'juggernaut_wrapper'), '-c', File.join(RAILS_ROOT, "config/juggernaut/test.yml")]
    @juggernaut_server = ExternalProcess.new argv
    # Java-way to export environment variables
    @juggernaut_server.environment.put('PATH', path)
    @juggernaut_server.output_file = File.join(RAILS_ROOT, 'log', 'juggernaut-test.log')
    @juggernaut_server.start
    sleep 20 # wait for juggernaut to setup
    assert @juggernaut_server.running?
    
    Rails.cache.clear
    @instance = JuggernautCache.instance
    @instance.send(:initialize)
    
    DomainChecks.disable do
      @user = users(:user_one)
      @project = projects(:bananorama)
      @juggernaut_session = JuggernautSession.create!(:user => @user, :domain => @user.domain, :project => @project)
    end
    @web = MockServer.new
    @flash = MockFlashClient.new(@juggernaut_session.id, @project.id)
  end

  def teardown
    sleep 0.2 # wait for fork to end
    @web.close if @web
    @flash.close if @flash
    if @juggernaut_server.running?
      @juggernaut_server.stop
    else
      puts "Juggernaut process was not running!"
    end
  end
  

  def test_when_new_user_comes_in_there_is_a_message_to_old_users
    DomainChecks.disable do
      @other_user = users(:banana_master)
      @other_session = JuggernautSession.create!(:user => @other_user, :domain => @user.domain, :project => @project)
      @second_flash = MockFlashClient.new(@other_session.id, @project.id)
    end
    do_subscribe
    locks = get_locks_from_flash_response
    assert_kind_of Array, locks
    sleep 3
    
    do_subscribe(@second_flash)
    get_locks_from_flash_response(@second_flash)
    
    message = get_message
    assert_not_nil message
    assert_not_nil message['envelope']
    assert_not_nil message['envelope']['logged_users']
    assert_equal "Ania Czajka, John Rambo", message['envelope']['logged_users']
    
    assert_raise Timeout::Error do #no more messages
      get_message(@second_flash) #we should not get any more message
    end
    
    do_logout(@second_flash)
    
    message = get_message #now we should get the operation=disconnected message
    assert_equal "disconnected", message['operation']
    assert_not_nil message
    assert_not_nil message['envelope']
    assert_not_nil message['envelope']['unlocked']
    
    
    
    message = get_message #now we should be informed about user disconnected
    assert_not_nil message
    assert_equal "connected_users", message['operation']
    assert_not_nil message['envelope']
    assert_not_nil message['envelope']['logged_users']
    assert_equal "Ania Czajka", message['envelope']['logged_users']
  end
  
  def test_we_get_messages_sent_beetween_session_creation_and_subscribe
    DomainChecks.disable { @other_project = projects(:second) }
    JuggernautCache.instance.broadcast("first message", [@project.id])
    JuggernautCache.instance.broadcast("second message", [@project.id])
    JuggernautCache.instance.broadcast("message we will not get", [@other_project.id])
    
    sleep 1

    do_subscribe
    
    locks = get_locks_from_flash_response
    assert_kind_of Array, locks
    
    assert_equal "first message", get_message
    assert_equal "second message", get_message
    
    
    assert_raise Timeout::Error do #no more messages
      get_message
    end
  end

  def test_subscribe_dialog_flash_response
    do_subscribe
    
    locks = get_locks_from_flash_response
    assert_kind_of Array, locks
    assert locks.empty?
  end

  def test_subscribe_dialog_session_subscribed
    do_subscribe

    assert_not_nil  @juggernaut_session.reload.subscribed_at
  end

  def test_subscribe_dialog_all_lock_sent
    make_some_locks
    do_subscribe

    locks = get_locks_from_flash_response
    expected = @locked_items.map(&:id).sort
    assert_equal expected, locks
  end

  def test_logout_removes_session
    do_subscribe
    do_logout

    assert !JuggernautSession.exists?(@juggernaut_session)
  end
  
  def test_session_can_be_used_only_to_listen_to_correct_project
    DomainChecks.disable { @other_project = projects(:second) }
    
    @flash = MockFlashClient.new(@juggernaut_session.id, @other_project.id)
    
    do_subscribe
    
    assert_equal "409 Conflict", @response.status
    
    sleep 1
    
    assert_raise Errno::EPIPE do #juggernaut just breaks the socket connection, doesn't make proper close
      @flash.socket.puts('a'+CR)
    end
    
    
  end

  private # helpers 

  def do_subscribe(flash = @flash)
    assert_difference '@web.requests.length', 1, "Messages: #{@web.requests.inspect}" do
      flash.subscribe
      sleep 0.5
    end
    process_request
  end

  def process_request
    req = @web.requests.shift
    assert_not_nil req
    request = req[:request]
    connection = req[:connection]
    post request.path_info, request.query
    @web.respond(@response.status, @response.body, connection)
  end

  def do_logout(flash = @flash)
    assert_difference '@web.requests.length', 2, "Messages: #{@web.requests.inspect}" do
      flash.close
      sleep 2
    end
    process_request
    process_request
  end

  def get_message(flash = @flash)
    response = flash.get_response
    assert_not_nil response['body']
    return response['body']
  end

  def get_locks_from_flash_response(flash = @flash)
    response = flash.get_response
    env = response && response['body'] && response['body']['envelope']
    env['locks']
  end

  def make_some_locks
    DomainChecks.disable do 
      user = users(:admin)
      @other_session = JuggernautSession.create!(:user => user, :domain => user.domain, :project => @project)
      @locked_items = @project.items[1..2]
      for item in @locked_items
        item.lock(@other_session)
      end
    end

  end

  class ThreadSafeArray
    def initialize
      @mutex = Mutex.new
      @internalArray = []
    end
    
    def ary
      @internalArray
    end
    
    def method_missing(method, *args, &block)
      @mutex.lock
      begin
        @internalArray.send(method, *args, &block)
      ensure
        @mutex.unlock
      end
    end
  end
  
  # Replaces Rails server, so that Juggernaut can send messages
  class MockServer
    attr_accessor :server
    attr_accessor :requests

    def initialize
      port = HOST[:webserver_port] 
      @server = TCPServer.new('127.0.0.1', port)
      @requests = ThreadSafeArray.new
      @thread = Thread.new do
        while (connection = @server.accept)
          request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
          request.parse(connection)
          @requests.push({ :connection => connection, :request => request})
        end
      end
    end

    def respond(status = 200, body = '', connection = nil)
      response = WEBrick::HTTPResponse.new(WEBrick::Config::HTTP)
      response.status = status
      response.body = body
      connection.print(response.to_s)
      connection.close
    end

    def close
      @thread.terminate
      @thread.join
      if @server and !@server.closed?
        @server.close
      end
      @requests.each do |request|
        if request[:connection] and !request[:connection].closed?
          request[:connection].close
        end
      end
    end

  end

  class MockFlashClient
    def initialize(session_id, channels)
      @session_id = session_id
      @channels = channels.kind_of?(Array) ? channels : [channels]
    end

    def subscribe
      host, port = HOST[:host], HOST[:port]
      @socket = TCPSocket.new(host, port)
      handshake = {
        :command => :subscribe,
        :session_id => @session_id,
        :client_id => @session_id,
        :channels => @channels
      }
      @socket.print(handshake.to_json + CR)
      @socket.flush
    end

    def get_response
      response = nil
      CSTimeout.timeout(15) { response = @socket.gets(CR) }
      ActiveSupport::JSON.decode(response.chop)
    end

    def close
      if @socket and  !@socket.closed?
        @socket.close
      end
    end
    
    def socket
      @socket
    end

  end

end

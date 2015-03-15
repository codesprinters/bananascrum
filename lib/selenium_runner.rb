class SeleniumRunner
  SELENIUM_LOG = "log/selenium-server.log"
  SELENIUM_SERVER = "vendor/selenium-server-1.0/selenium-server.jar"
  SELENIUM_EXTENSIONS = "test/selenium/user-extensions.js"
  SELENIUM_SERVER_PORT = ENV["selenium_server_port"] || "4446"

  attr_accessor :exec_args, :builder, :server

  def initialize
    self.exec_args = [
      "java",
      "-jar", File.join(RAILS_ROOT, SELENIUM_SERVER),
      "-port", SELENIUM_SERVER_PORT,
      "-userExtensions", File.join(RAILS_ROOT, SELENIUM_EXTENSIONS)
    ]
    @selenium_server = ExternalProcess.new(self.exec_args)
    @selenium_server.output_file = 'selenium-server.log'
  end

  def run
    prepare_environment
    @selenium_server.start
  end

  def stop
    @selenium_server.stop if @selenium_server.running?
  end

  protected
  def prepare_environment
    env = @selenium_server.environment
    unless ENV['DISPLAY']
      env.put("DISPLAY", ":99")
    end

    # Necessary for Debian where /usr/bin/firefox is a script
    if File.directory?("/usr/lib/iceweasel")
      current_path = env.get("PATH")
      env.put("PATH", "/usr/lib/iceweasel:" + current_path)
    end
  end
end

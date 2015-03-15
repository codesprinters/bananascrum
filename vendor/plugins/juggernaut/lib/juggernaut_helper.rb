module Juggernaut # :nodoc:
  module JuggernautHelper

    def juggernaut(options = {})
      hosts = Juggernaut::CONFIG[:hosts].select {|h| !h[:environment] or h[:environment] == ENV['RAILS_ENV'].to_sym }
      random_host = hosts[rand(hosts.length)]
      options = {
        :host                 => (random_host[:public_host] || random_host[:host]),
        :port                 => (random_host[:public_port] || random_host[:port]),
        :width                => '0px',
        :height               => '0px',
        :session_id           => nil,
        :swf_address          => "/juggernaut/juggernaut.swf",
        :ei_swf_address       => "/juggernaut/expressinstall.swf",
        :flash_version        => 8,
        :flash_color          => "#fff",
        :swf_name             => "juggernaut_flash",
        :bridge_name          => "juggernaut",
        :debug                => (RAILS_ENV != 'production'),
        :reconnect_attempts   => 3,
        :reconnect_intervals  => 3
      }.merge(options)
      
      javascript_tag("
        bs.juggernautOptions = #{options.to_json};
        new Juggernaut(bs.juggernautOptions);
      ")
    end

  end
end

JuggernautHelper = Juggernaut::JuggernautHelper unless defined?(JuggernautHelper)


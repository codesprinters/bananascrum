require 'yaml'

class AppConfigLoader
  # values in this array can be modified without passing them to allowed_values
  @@all_allowed = ["action_mailer"]

  # Loads given YAML file into config of the application
  # values are later available under AppConfig.key
  #
  # options can contain :allowed_values key with whitelist of values
  # that can be inserted into config.
  # If no :allowed_values is given all parsed values are inserted into config.
  def self.load(config, file, options = {})
    @@options = options
    @@config = config
    yaml = {}
    
    File.open(file) do |f|
      yaml = YAML.load(f.read)[RAILS_ENV]
    end

    if yaml.nil? || yaml.empty?
      return
    end
    
    yaml.each do |key, value|
      config_option = self.config_option_to_list(key)
      if options[:allowed_values]
        self.handle_allowed_values(config_option, value)
      else
        self.set_value(config_option, value)
      end
    end
  end

  private

  # sets value in config
  def self.set_value(config_option, value)
    # We use eval here, because config option may contain hash keys
    eval("@@config.#{config_option.join('.')} = value")
  end

  # Deals with logic when allowed values hash is passed to load
  def self.handle_allowed_values(config_option, value)
    if @@options[:allowed_values].include?(config_option.last) || @@all_allowed.include?(config_option.first)
      self.set_value(config_option, value)
    end
  end

  # Retrieves config option from key
  # It returns list sections as strings
  # for ex. in action_mailer.delivery_method: smtp - action_mailer is a config section
  def self.config_option_to_list(key)
    parts = key.split('.')
    if parts.length > 1
      parts
    else
      ['app_config', key]
    end
  end
end

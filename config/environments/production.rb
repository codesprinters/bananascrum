# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

config.cache_store = :mem_cache_store, "localhost" 

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching            = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# ActionMailer::Base.deliveries array.
# this might be overwritten by customconfig.yml
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default_charset = "utf-8"

# Lines below enable threadsafe dispatching. Eager loading is required in order to solve the problem with different behaviour of ActiveSupport::Dependencies 
config.threadsafe! unless $rails_rake_task
config.eager_load_paths << "#{RAILS_ROOT}/lib"
config.eager_load_paths << "#{RAILS_ROOT}/app/forms"
# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.

config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

config.cache_store = :mem_cache_store, "localhost" 

config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => 'localhost',
  :port => 25,
  :domain => 'bananascrum.com'
}

# Lines below enable threadsafe dispatching. Eager loading is required in order to solve the problem with different behaviour of ActiveSupport::Dependencies 
config.threadsafe! unless $rails_rake_task
config.eager_load_paths << "#{RAILS_ROOT}/lib"
config.eager_load_paths << "#{RAILS_ROOT}/app/forms"
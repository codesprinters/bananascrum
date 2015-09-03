# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
# <%= '# ' if freeze %>RAILS_GEM_VERSION = '<%= Rails::VERSION::STRING %>' unless defined? RAILS_GEM_VERSION
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'plugins/app_config/lib/configuration'
require 'app_config_loader'
require 'active_support'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  config.plugins = [ :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/mixins
                           #{RAILS_ROOT}/app/models/support
                           #{RAILS_ROOT}/app/forms
                           #{RAILS_ROOT}/app/controllers/abstract
                           #{RAILS_ROOT}/app/controllers/mixins
                           #{RAILS_ROOT}/app/controllers/sweepers
                           #{RAILS_ROOT}/lib
                           #{RAILS_ROOT}/lib/charts
                           #{RAILS_ROOT}/lib/cards
                           #{RAILS_ROOT}/vendor/itext
                           #{RAILS_ROOT}/vendor/gems/rmagick-2.8.0/ext/RMagick
                           #{RAILS_ROOT}/vendor/gems/facets-2.5.0/lib/core/ )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => "_bananascrum_" + (ENV['RAILS_ENV'] || ""),
    :secret      => ActiveSupport::SecureRandom.hex(16)
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Set default time zone (this enables Rails 2.1 time zone features)
  config.time_zone = 'UTC'

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Gem dependencies
  config.gem "icalendar"
  #config.gem "right_aws"
  #config.gem "right_http_connection"
  #config.gem "thoughtbot-factory_girl", :lib => "factory_girl", :source => "http://gems.github.com"
  config.gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
  #config.gem "faker"
  config.gem "jruby-openssl", :lib => 'openssl'
  # eventmachine is not needed by Rails server, but it needs to be builded
  config.gem "eventmachine"
  config.gem "prawn", :version => '= 0.5.1'
  config.gem "prawn-core", :lib => 'prawn/core', :version => '= 0.5.1'
  config.gem "prawn-format", :lib => 'prawn/format', :version => '= 0.2.1'
  config.gem "prawn-layout", :lib => 'prawn/layout', :version => '= 0.2.1'
  config.gem "mime-types", :lib => 'mime/types'
  config.gem 'rack', :version => '= 1.0.1'

  # Gem dependencies for running tests
  #config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com"
  #config.gem "mocha"
  #config.gem "RedCloth", :lib => 'redcloth'
  #config.gem "archive-tar-minitar", :lib => 'archive/tar/minitar'
  #config.gem "ci_reporter", :lib => 'ci/reporter/rake/test_unit_loader'
  #config.gem "builder"

  # JDBC can't dump primary keys, see
  # http://jkollage.blogspot.com/2007/05/acitverecord-jdbc-jtds-dbschemadump-i.html
  # http://kofno.wordpress.com/2006/10/11/jruby-and-activerecord-schema-dump/
  # http://stackoverflow.com/questions/383058/rails-schema-creation-problem
  config.active_record.schema_format = :sql

  # jRuby related dependecies
  config.gem "jruby-jars"
  config.gem "activerecord-jdbc-adapter", :lib => 'active_record/connection_adapters/jdbc_adapter'
  config.gem "activerecord-jdbcmysql-adapter", :lib => 'active_record/connection_adapters/jdbcmysql_adapter'

  # JDBC can't dump primary keys, see
  # http://jkollage.blogspot.com/2007/05/acitverecord-jdbc-jtds-dbschemadump-i.html
  # http://kofno.wordpress.com/2006/10/11/jruby-and-activerecord-schema-dump/
  # http://stackoverflow.com/questions/383058/rails-schema-creation-problem
  config.active_record.schema_format = :sql

  # Application config
  AppConfigLoader.load(config, File.join(RAILS_ROOT, 'config', 'appconfig.yml'))
  AppConfigLoader.load(config, File.join(RAILS_ROOT, 'config', 'customconfig.yml'))
end

NEGATIVE_CAPTCHA_SECRET = '7ca6ea5f20e7a01e57813f6cfb8e30184f1c6a58795aef161082a9267383f7da809c9053f1423a0e8fa7cec2517cd08a48b368b1d19c0e2e637cd2ef94962a3f'

INVOICES_ROOT = "#{RAILS_ROOT}/uploads/invoices"
REBILLING_ROOT = "#{RAILS_ROOT}/uploads/rebilling"

# regenerate less js routes
Less::JsRoutes.generate!

ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| "<div class=\"field-with-errors\">#{html_tag}</div>" }

# Add Foreign key extensions
require 'foreign_keys_extensions'
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ForeignKeysExtensions)
require 'schema_dumper'
ActiveRecord::SchemaDumper.send(:include, SchemaDumper)

# Dependency required by cookie_store.rb. This failes to be loaded by eager loading
require 'active_support/secure_random'


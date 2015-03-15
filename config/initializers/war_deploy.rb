# Runs migrations after initialize Rails.
# Required for updating bananajam to new version.

if $PROGRAM_NAME.match(/web.xml/) || RAILS_ENV == 'development'
  DatabaseInitializer.new(ActiveRecord::Base.connection).run
end

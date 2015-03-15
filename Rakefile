# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'tasks/rails'

require 'rubygems'
gem 'ci_reporter'
require 'ci/reporter/rake/test_unit'

begin
  # Optionally use metric_fu gem
  require 'metric_fu'
rescue LoadError
end

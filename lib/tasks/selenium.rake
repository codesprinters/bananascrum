require "find"
require "selenium_runner"
require "external_process"



namespace :selenium do
  SELENIUM_LOG = "log/selenium-server.log"
  SELENIUM_SERVER = "vendor/selenium-server-1.0/selenium-server.jar"
  SELENIUM_EXTENSIONS = "test/new_selenium/user-extensions.js"

  def cc_artifacts_dir
    out = ENV['CC_BUILD_ARTIFACTS'] || "cc_artifacts"
    mkdir_p(out) unless File.directory?(out)
    out
  end

  desc "Purge test database and reload all migrations"
  task :prepare => :environment do
    # Works only on test database
    ENV['RAILS_ENV'] = 'selenium'

    Rake::Task['db:test:purge'].invoke

    # This hack is needed because db:test:purge implementation for MySQL drops the test database, invalidating
    # the existing connection. A solution is to reconnect again.
    configurations = ActiveRecord::Base.configurations
    if configurations and configurations.has_key?("test") and configurations["test"]["adapter"] == 'mysql'
      ActiveRecord::Base.establish_connection(:test)
    end

    Rake::Task['db:migrate'].invoke

    # Hack, pretend we haven't invoked purge so Rails can execute it again
    Rake::Task['db:test:purge'].instance_eval "@already_invoked = false"
  end

  desc "Run Selenium tests under CruiseControl.rb"
  task :start => ["screenshots:clean", "log:clear", "db:populate", "start:server", "start:test"]

  namespace :start  do
    desc "Start Selenium RC server and ensure it is stopped on exit"
    task :server do

      # TODO Save the output of the subprocess somewhere
      puts "Starting Selenium RC server"
      selenium_runner = SeleniumRunner.new
      selenium_runner.run
      ENV['selenium_server_port'] = SeleniumRunner::SELENIUM_SERVER_PORT

      # Kill the server on exit
      at_exit do
        puts "Stopping Selenium RC server"
        selenium_runner.stop
        if Dir["screenshots/*"].empty?
          sh "touch screenshots/test.png"
        end
      end

      # Wait to ensure the server has time to boot
      sleep 1
    end

    Rake::TestTask.new(:test) do |t|
      t.libs << "test"
      t.pattern = 'test/new_selenium/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task['selenium:start:test'].comment = "Run the Selenium tests in test/new_selenium"
  end


  namespace :screenshots do
    desc "Clean screenshots directory"
    task :clean do
      sh "rm -rf screenshots/*"
    end
  end
end

require "find"
require "selenium_runner"
require "external_process"

task :cruise => ["cruise:test_rcov", "cruise:metrics", "cruise:doc"]

namespace :cruise do
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

  desc "Run all tests"
  task :test => :prepare do
    Rake::Task['test'].invoke
  end

  desc "Run tests and move coverage reports to CC artifacts dir"
  task :test_rcov => :prepare do
    out = cc_artifacts_dir

    ENV['SHOW_ONLY'] = "app/models,app/helpers,lib"
    Rake::Task["test:units:rcov"].invoke
    mv 'coverage/units', "#{out}/units_rcov"

    ENV['SHOW_ONLY'] = "controllers"
    Rake::Task["test:functionals:rcov"].invoke
    mv 'coverage/functionals', "#{out}/functionals_rcov"

    Rake::Task["test:integration"].invoke
  end

  desc "Generate different code metrics"
  task :metrics => [:stats, :notes]

  desc "Check code style with Roodi"
  task :roodi do
    out = cc_artifacts_dir

    files = []
    Find.find("app", "lib") do |path|
      next unless path.match(/\.rb$/)
      files << "'#{path}'"
    end

    open(File.join(out, "roodi"), "w") do |out_file|
      out_file << IO.popen("roodi " + files.join(" ")) {|f| f.readlines }
    end
  end

  desc "Generate project statistics"
  task :stats do
    sh "rake -s stats > '#{cc_artifacts_dir}/stats'"
  end
  
  desc "Generate project notes"
  task :notes do
    sh "rake -s notes > '#{cc_artifacts_dir}/notes'"
  end

  desc "Generate project documentation"
  task :doc => "doc:sphinx" do
    sh "mv doc/_build/html '#{cc_artifacts_dir}/doc'"
  end

  desc "Run Selenium tests under CruiseControl.rb"
  task :selenium => ["screenshots:clean", "log:clear", "db:populate", "selenium:server", "selenium:test"]

  namespace :selenium do
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
      t.pattern = 'test/selenium/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task['cruise:selenium:test'].comment = "Run the Selenium tests in test/selenium"
  end


  namespace :screenshots do
    desc "Clean screenshots directory"
    task :clean do
      sh "rm -rf screenshots/*"
    end
  end
end

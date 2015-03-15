require 'mysql_dumper'

namespace :db do
  desc "Destroys data in db and populates it with test data"
  task :populate => ['db:populate:data', 'db:populate:dump', 'db:populate:plans']

  task :jmeter => ['db:jmeter:data']

  namespace :populate do
    desc "Replace current database with populate data"
    task :data => ['db:migrate:reset'] do
      ActiveRecord::Base.send(:subclasses).each do |model|
        model.reset_column_information
      end
      
      SeleniumDataGenerator.new.generate
    end

    desc "Create populate dump from the current database"
    task :dump => :load_config do
      dumper = MysqlDumper.new(ActiveRecord::Base.configurations[RAILS_ENV])
      dumper.dump("#{RAILS_ROOT}/db/populate.dump")
    end

    desc "Restore current database from populate dump"
    task :restore => :load_config  do
      dumper = MysqlDumper.new(ActiveRecord::Base.configurations[RAILS_ENV])
      dumper.restore("#{RAILS_ROOT}/db/populate.dump")
    end

    task :themes do
      ENV['FIXTURES'] = 'themes'
      ENV['FIXTURES_PATH'] = 'lib'
      Rake::Task["db:fixtures:load"].invoke  
    end
    
    desc "Populate data with public plans"
    task :plans => :environment do
      Plan.update_all(:public => false)
      Plan.create!(:name => "Free", :public => true, :price => nil, :timeline_view => false, :ssl => false, :items_limit => 20, :users_limit => 3, :projects_limit => 1, :valid_from => Time.now, :mbytes_limit => 300)
      Plan.create!(:name => "Basic", :public => true, :price => "12", :timeline_view => false, :ssl => false, :users_limit => 8, :projects_limit => 5, :valid_from => Time.now, :mbytes_limit => 2048, :ssl => true)
      Plan.create!(:name => "Standard", :public => true, :price => "18", :timeline_view => true, :ssl => true, :users_limit => 14, :projects_limit => 8, :valid_from => Time.now, :mbytes_limit => 5120, :ssl => true)
      Plan.create!(:name => "Unlimited", :public => true, :price => "80", :timeline_view => true, :ssl => true, :valid_from => Time.now, :ssl => true)
      Plan.create!(:name => "Pro", :public => true, :price => "37", :timeline_view => true, :ssl => true, :items_limit => nil, :projects_limit => 15, :users_limit => 20, :valid_from => Time.now, :mbytes_limit => 10240, :ssl => true)
      Plan.create!(:name => "Transition", :public => false, :price => nil, :timeline_view => true, :ssl => true, :valid_from => Time.now, :ssl => true, :mbytes_limit => 3072)
      Plan.create!(:name => "Edu", :public => false, :price => nil, :timeline_view => true, :ssl => true, :valid_from => Time.now, :ssl => true, :mbytes_limit => 3072)
    end

  end



  namespace :jmeter do
    desc "Prepare database to jmeter tests"
    task :data => ['db:migrate:reset'] do
      ActiveRecord::Base.send(:subclasses).each do |model|
        model.reset_column_information 
      end
      JmeterDataGenerator.new.generate
    end

  end
  
  namespace :test do
    desc "Destroys data in test db and populates it with test data"
    task :populate do
      RAILS_ENV = "test"
      Rake::Task["db:populate"].invoke
    end
  end
end

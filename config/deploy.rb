set :application, "bananascrum"
set :deploy_to, "/home/bananascrum/bananascrum.production"
set :user, "bananascrum"
set :use_sudo, false
set :deploy_via, :remote_cache
set :scm, :git
set :repository, "git+ssh://runner.codesprinters.com/srv/git/bananascrum.git/"

set :branch do
  fail "Provide TAG environment variable to select tag to deploy from." if ENV['TAG'].nil?
  ENV['TAG']
end

server "173.203.106.107:22000", :app, :web, :db, :primary => true
server "173.203.109.213:22000", :app, :web, :db
# to deploy on staging only run
# cap HOSTS=173.203.109.213:22000 deploy TAG=<sth>

namespace :deploy do
  desc "Deploy the project including migrations"
  task :default, :roles => :app do
    maintenance_enable
    migrations
#    juggernaut.restart
#    demo.reload
    cache.clear
    maintenance_disable
  end

  task :finalize_update, :roles => :app do
    run "chmod -R g+w #{release_path}"
    %w{bananascrum siteadmin}.each do |app|
      run "rm -rf #{release_path}/#{app}/log #{release_path}/#{app}/public/system #{release_path}/#{app}/tmp/pids &&\
           mkdir -p #{release_path}/#{app}/public &&\
           mkdir -p #{release_path}/#{app}/tmp &&\
           ln -s #{shared_path}/#{app}/log #{release_path}/#{app}/log &&\
           ln -s #{shared_path}/#{app}/system #{release_path}/#{app}/public/system &&\
           ln -s #{shared_path}/#{app}/pids #{release_path}/#{app}/tmp/pids"
    end
  end

  task :after_update_code, :roles => :app do
    # Symlink configuration
    run "ln -s #{shared_path}/bananascrum/config/database.yml #{release_path}/bananascrum/config/database.yml"
    #run "ln -s #{shared_path}/config/amazon_s3.yml #{release_path}/config/amazon_s3.yml"

    # Symlink uploads
    run "rm -rf #{release_path}/bananascrum/uploads"
    run "ln -s #{shared_path}/bananascrum/uploads #{release_path}/bananascrum/uploads"

    dirs = []
    %w{bananascrum siteadmin}.each do |app|
      %w{images stylesheets javascripts}.each do |dir|
        dirs << "#{release_path}/#{app}/public/#{dir}"
      end
    end
    run "find #{dirs.join(' ')} -exec touch -t #{Time.now.strftime('%Y%m%d%H%M.%S')} {} ';'; true"
    #run "find #{release_path}/public/images #{release_path}/public/stylesheets #{release_path}/public/javascripts -exec touch -t #{Time.now.strftime('%Y%m%d%H%M.%S')} {} ';'; true"

    #Time.now.strftime '%Y%m%d%H%M.%S'
  end

  task :migrate, :roles => :db do
    run "cd #{release_path}/bananascrum && jruby -S rake RAILS_ENV=production db:migrate"
  end

  desc "Restart the application server"
  task :restart, :roles => :app do
      run "/srv/glassfishv3/bin/asadmin restart-domain --domaindir /home/bananascrum/glassfish production"
  end

  desc "Enable the maintenance info"
  task :maintenance_enable, :roles => :app do
      run "touch /home/bananascrum/bananascrum.production/maintenance.txt"
  end

  desc "Enable the maintenance info"
  task :maintenance_disable, :roles => :app do
    # glassfish restart takes a long time, so we keep the maintenance screen
    # up a bit longer
    sleep 80
    run "rm /home/bananascrum/bananascrum.production/maintenance.txt"
  end


  namespace :demo do
    desc "Reload the demo database"
    task :reload, :roles => :app do
      run "cd #{current_path}/bananascrum && jruby -S rake demo:reload RAILS_ENV=production"
    end
  end

  namespace :cache do
    desc "Clear application cache"
    task :clear, :roles => :app do
      run "cd #{current_path}/bananascrum && jruby -S rake cache:clear"
    end
  end

  namespace :juggernaut do
    desc "Start the Juggernaut server"
    task :start, :roles => :app do
      run "cd #{current_path}/bananascrum && rake juggernaut:start"
    end

    desc "Stop the Juggernaut server"
    task :stop, :roles => :app do
      run "cd #{current_path}/bananascrum && rake juggernaut:stop"
    end

    desc "Restart the Juggernaut server"
    task :restart, :roles => :app do
      run "cd #{current_path}/bananascrum && rake juggernaut:restart"
    end
  end
end

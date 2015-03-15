namespace :dist do
  desc "Build standalone juggernaut instance"
  task "juggernaut" do
    sh "cd #{RAILS_ROOT} && cd juggernaut-jar && rake"
    sh "mv juggernaut-jar/pkg/livesync.jar build/livesync"
  end
  desc "Create bananascrum dist package in build directory"
  task "build" => ['war:package', 'dist:juggernaut', 'dist:cleanup']

  desc "Create shippable .tar.gz package"
  task "package" => ["dist:build"] do
    package_dir = 'BananaScrum-' + BananaScrum::Version::STRING
    exclude_files = ['livesync_hosts.yml', 'config.yml', 'database.yml', 'livesync/logs/*']
    exclude_opts = exclude_files.map { |f| "--exclude '#{f}'" }.join(' ')
    sh "ln -Tsf build #{package_dir}"
    sh "tar chvzf #{package_dir}.tar.gz #{package_dir} #{exclude_opts}"
    sh "rm #{package_dir}"
  end
  
  desc "Clear tmp build directory"
  task "cleanup" do
    if File.exist?("#{RAILS_ROOT}/tmp/war") 
      FileUtils.cd("#{RAILS_ROOT}/tmp/war") do
        sh 'rm -rf *'
      end
    end
  end

  desc "Build daily package"
  task "daily" => ["dist:package"] do
    target_dir = '/home/hudson/www/war/daily'
    package_file = "BananaScrum-#{BananaScrum::Version::STRING}"
    sh "mv #{package_file}.tar.gz #{target_dir}/#{package_file}-#{Date.today}.tar.gz"
  end
end

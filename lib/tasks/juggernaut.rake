namespace :juggernaut do
  task :prepare_juggernaut do
    @juggernaut = 'lib/juggernaut_wrapper'
    @rails_env = ENV["RAILS_ENV"] || "development"
    @command = "#{@juggernaut} -c config/juggernaut/#{@rails_env}.yml"
  end

  desc "Starts Juggernaut"
  task :start => :prepare_juggernaut do
    @command << " -d"

    puts "Starting juggernaut using config/juggernaut/#{@rails_env}.yml"
    unless system(@command)
      puts "Error starting"
    end
  end

  desc "Stops all Juggernauts"
  task :stop => :prepare_juggernaut do
    @command << " -k"

    if system(@command)
      puts "Juggernaut stopped"
    else
      puts "Error stopping juggernaut"
    end
  end

  desc "Restarts Juggernaut"
  task :restart => [:stop, :start]
end

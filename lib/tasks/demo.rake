namespace :demo  do
  desc "Regenerates demo domain to it's pristine state.
        Also creates domain if was not present"
  task :reload => :environment do
    puts "Regenerating demo"
    generator = DemoDataGenerator.new
    generator.regenerate
  end

end

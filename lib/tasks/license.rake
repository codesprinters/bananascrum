namespace :license do

  major_version = lambda do
    ENV['major_version'] || BananaScrum::Version::MAJOR
  end

  desc "Generates private and public keys pair for licenses"
  task :generate_keypair do
    LicenseKey::Generator.new(major_version.call).generate_keypair
  end

  desc "Generate license key for given client"
  task :generate do
    entity_name = ENV['entity_name']
    valid_to = ENV['valid_to']
    
    unless entity_name
      puts "usage: rake license:generate entity_name=<name> (valid_to=<date>)"
      exit 1
    end

    puts LicenseKey::Generator.new(major_version.call).generate_license(entity_name, valid_to)
  end

end

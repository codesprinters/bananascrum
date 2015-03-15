namespace :setup do
  desc "Creates a default domain for standalone version of BananaScrum"
  task :default_domain => :environment do
    DomainChecks.disable do
      if Domain.find_by_name(AppConfig::default_domain)
        puts "Default domain already exists"
      else
        puts "Creating a default domain: #{AppConfig::default_domain}"
        Domain.delete_all
        Domain.create_default
      end
    end
  end
end
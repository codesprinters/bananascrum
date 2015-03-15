namespace :bootstrap do

  desc "Creates project-independent default values for dictionaries/enums"
  task :create_defaults => :environment do
    ImpedimentAction.create_defaults
  end
  
  
  task :create_and_assign_plans => [:create_rabbit_friends_plan, :add_domains_to_rabbit_friends_plan]
  
  desc "Creates rabbit friends plan. It will overwrite this plan if it already exist"
  task :create_rabbit_friends_plan => :environment do
    rabbit_plan = Plan.find_by_name("Rabbit friends")
    rabbit_plan.destroy if rabbit_plan
    Plan.create(
      :name => "Rabbit friends",
      :valid_from => Date.today,
      :users_limit => 40,
      :projects_limit => 10,
      :mbytes_limit => 2048
    )
    puts 'Created Rabbit Friends plan successfully'
  end
  
  desc "Assigns domains with no plan to rabbit plan"
  task :add_domains_to_rabbit_friends_plan => :environment do
    rabbit_plan = Plan.find_by_name("Rabbit friends")
    raise 'There is no rabbit plan created' unless rabbit_plan
    domains = Domain.find(:all, :conditions => ['plan_id IS NULL OR plan_id = 0'])
    
    Domain.transaction do
      domains.each do |d|
        d.plan = rabbit_plan
        d.save!
      end
    end
  
    puts 'All domains assigned now'
  end
end


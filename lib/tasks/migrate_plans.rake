namespace :app do
  desc "Set correct plans to domains. This is to be used once on 1 April 2010"
  task :migrate_plans => :environment do
    free = Plan.find_by_name "Free"
    trans = Plan.find_by_name "Transition"
    if free.nil? || trans.nil?
      raise "Plan Free or Transition not available in database"
    end
    
    ActiveRecord::Base.connection.execute("UPDATE domains SET plan_id = #{free.id}")
    ActiveRecord::Base.connection.execute("UPDATE domains SET plan_id = #{trans.id} WHERE domains.id IN (SELECT domain_id FROM users WHERE last_login > DATE_ADD(NOW(), INTERVAL -1 MONTH) GROUP BY domain_id HAVING COUNT(*) > 0)")
  end
end
namespace :app do
  desc "Generate application statistics"
  task :stats => "stats:console"

  namespace :stats do
    MUNIN_FIELDS = [:domains, :projects, :users, :sprints, :items, :tasks, :active_users, :active_domains, :juggernaut_clients]

    if ENV['MUNIN_FIELDS']
      # Override for default fields
      MUNIN_FIELDS = ENV['MUNIN_FIELDS'].split.map(&:to_sym)
    end

    task :generate => :environment do
      condition = "domains.name not in ('cs', 'demo')"
      @stats = {}
      @stats[:domains] = Domain.count :conditions => condition
      @stats[:projects] = Project.count :include => :domain, :conditions => condition
      @stats[:users] = User.count :include => :domain, :conditions => condition
      @stats[:sprints] = Sprint.count :include => { :project => :domain }, :conditions => condition
      @stats[:items] = Item.count :include => { :project => :domain }, :conditions => condition
      @stats[:tasks] = Task.count :include => { :item => { :project => :domain } }, :conditions => condition
      @stats[:regs] = Domain.count :conditions => "created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)"
      @stats[:active_users] = User.count :include => :domain, :conditions => condition + " AND last_login > '#{1.month.ago.to_date.to_s(:db)}'" 
      @stats[:active_domains] = Domain.count :include => [ :users ], :conditions => condition + " AND users.last_login > '#{1.month.ago.to_date.to_s(:db)}'"
      @stats[:juggernaut_clients] = Juggernaut.show_clients.length rescue 0

      @stats[:projects_per_domain] = @stats[:projects].to_f/@stats[:domains]
      @stats[:users_per_domain] = @stats[:users].to_f/@stats[:domains]
      @stats[:sprints_per_project] = @stats[:sprints].to_f/@stats[:projects]
      @stats[:items_per_project] = @stats[:items].to_f/@stats[:projects]
      @stats[:items_per_sprint] = @stats[:items].to_f/@stats[:sprints]
      @stats[:tasks_per_item] = @stats[:tasks].to_f/@stats[:items]
    end

    desc "Generate application statistics"
    task :console => :generate do
      puts "Banana Scrum statistics for #{Time.now}"
      puts "(excluding cs and demo domains)"
      puts
      printf "Domains: %d\n", @stats[:domains]
      printf "Projects: %d\n", @stats[:projects]
      printf "Projects/domain: %.2f\n", @stats[:projects_per_domain]
      printf "Users: %d\n", @stats[:users]
      printf "Users/domain: %.2f\n", @stats[:users_per_domain]
      printf "Sprints: %d\n", @stats[:sprints]
      printf "Sprints/project: %.2f\n", @stats[:sprints_per_project]
      printf "Items: %d\n", @stats[:items]
      printf "Items/project: %.2f\n", @stats[:items_per_project]
      printf "Items/sprint: %.2f\n", @stats[:items_per_sprint]
      printf "Tasks: %d\n", @stats[:tasks]
      printf "Tasks/item: %.2f\n", @stats[:tasks_per_item]
      printf "New domains within last 24h: %d\n", @stats[:regs]
    end

    desc "Generate statistics in Munin format"
    task :munin => :generate do
      MUNIN_FIELDS.each do |key|
        puts "#{key}.value #{@stats[key]}"
      end
    end

    desc "Generate Munin configuration"
    task :munin_config do
      puts "graph_title Banana Scrum statistics"
      puts "graph_args -l 0"
      puts "graph_scale no"
      MUNIN_FIELDS.each do |key|
        puts "#{key}.label #{key}"
      end
    end

    desc "Save statistics to database"
    task :db => [:environment, :generate] do
      run = StatRun.create!(:timestamp => Time.current)
      puts "Statistics run #{run.id}"

      MUNIN_FIELDS.each do |key|
        datum = StatDatum.create!(:kind => key.to_s, :value => @stats[key], :stat_run => run)
        puts "Inserted #{datum.kind} => #{datum.value}"
      end
    end

    desc "Generate detailed statistics"
    task :detailed => [:environment] do
      require 'csv'

      if ENV["RUN_DATE"]
        run_date = ENV["RUN_DATE"].to_date
      else
        run_date = Date.today
      end
      range = (run_date - 180.days)..run_date
      lines = []
      titles = ["Date",
        "Domains with at least 5 users",
        "Domains with at least 3 projects",
        "All domains",
        "Active domains",
        "Inactive domains",
        "All projects",
        "Projects with at least 5 sprints",
        "Projects with ongoing sprints",
        "Items",
        "Tasks",
        "Sprints",
        "Users"
      ]
      lines << CSV.generate_line(titles, ";")
      for date in range
        max_last_login = date - 7.days
        all_domains = Domain.all_at_date(date)
        inactive = Domain.inactive_domains(max_last_login)
        active = all_domains - inactive
        projects = Project.count(:conditions => ["created_at < ?", date])
        users = User.count(:conditions => ["created_at < ?", date])
        sprints = Sprint.count(:conditions => ["created_at < ?", date])
        items = BacklogItem.count(:conditions => ["created_on < ?", date])
        tasks = Task.count(:conditions => ["created_on < ?", date])
        row = [
          date,
          Domain.with_at_least_users(date),
          Domain.with_at_least_projects(date),
          all_domains,
          active,
          inactive,
          projects,
          Project.with_at_least_sprints(date),
          Project.with_active_sprint(date),
          items,
          tasks,
          sprints,
          users
        ]
        lines << CSV.generate_line(row, ";")
      end

      puts lines.join("\n")

    end
    
  end
end

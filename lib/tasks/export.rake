namespace :export do

  get_domain_id = lambda do
    domain_id = ENV['domain_id']
    raise Exception.new('domain_id is required') unless domain_id
    
    return domain_id
  end
  
  config = Rails::Configuration.new
  db_config = lambda do |field|
    return config.database_configuration[RAILS_ENV][field.to_s]
  end

  task :domain do
    domain_id = get_domain_id.call

    dump = lambda do |tables, where|
      where = "--where '#{where}'" if where
      tables = tables.join(' ')
      command = "mysqldump -t -c --compact -u #{db_config[:username]} -p#{db_config[:password]} #{db_config[:database]} #{tables} #{where}"
      sql = `#{command}`

      # add extra lines separator, required in import
      puts sql.gsub("\n", "\n\n")
    end

    # TODO get all tables with domain_id column
    tables = [
      'projects', 'sprints', 'backlog_elements', 'comments',
      'tasks', 'task_logs',
      'tags', 'item_tags',
      'impediments', 'impediment_logs',
      'users', 'user_activations',
      'role_assignments', 'clips'
    ]

    # Find the customer id since there's no domain_id in customers table
    customer_id = Domain.find(domain_id).customer_id

    dump.call(['impediment_actions'], nil)
    dump.call(['domains'], "id = #{domain_id}")
    dump.call(['customers'], "id = #{customer_id}")
    dump.call(tables, "domain_id = #{domain_id}")
  end

  task :attachments => :environment do
    domain_id = get_domain_id.call
    
    DomainChecks.disable do
      clips = Clip.find(:all, :conditions => "domain_id = #{domain_id}")

      Dir.mktmpdir do |tmp_dir|

        # copy attachments to temporary directory
        clips.each do |clip|
          clip_dir = File.join(tmp_dir, clip.id.to_s)
          Dir.mkdir(clip_dir)
          FileUtils.cp(clip.content.path, clip_dir)
        end

        # create zip archive
        Zip::Archive.open(File.join(RAILS_ROOT, "domain_#{domain_id}_attachments.zip"), Zip::CREATE) do |archive|
          Dir.glob("#{tmp_dir}/**/*").each do |path|
            zip_path = path.gsub(tmp_dir, '')

            if File.directory?(path)
              archive.add_dir(zip_path)
            else
              archive.add_file(zip_path, path)
            end
          end
        end

      end
    end
  end

end

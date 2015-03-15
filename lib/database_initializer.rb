class DatabaseInitializer

  INITIAL_SQL_FILES_PATH = "#{RAILS_ROOT}/db/initial"

  def initialize(connection)
    @connection = connection
    @clean_database = nil
  end

  def run
    # create the database schema and load intinial data in necessary
    if clean_database?
      load_schema
      load_initial_data unless import_domain?
    end

    # Migrator.new initializes schema_migrations table
    @migrator = ActiveRecord::Migrator.new(:up, RAILS_ROOT + "/db/migrate")
    
    if pending_migrations?
      run_migrations
    end

    # import domain's data from bananascrum.com
    if clean_database? and import_domain?
      import_domain
    end
  end

  private

  def clean_database?
    return @clean_database unless @clean_database.nil?
    
    begin
      @connection.execute('SHOW CREATE TABLE schema_migrations')
      @clean_database = false
    rescue ActiveRecord::StatementInvalid
      # can't find schema_migrations table, create the initial database schema
      @clean_database = true
    end

    return @clean_database
  end

  def import_domain?
    return File.exist?(sql_file_path('import.sql'))
  end

  def pending_migrations?
    @migrator.pending_migrations.any?
  end

  def sql_file_path(file_name)
    return File.join(INITIAL_SQL_FILES_PATH, file_name)
  end

  def run_sql_commands_from(file_name)
    IO.readlines(sql_file_path(file_name)).join.split("\n\n").each do |sql|
      puts sql
      @connection.execute(sql)
    end
  end

  def load_schema
    puts_step 'Create database schema'
    disable_foreign_key_checks { run_sql_commands_from("schema.sql") }

    puts_step 'Load schema_migrations'
    @connection.transaction { run_sql_commands_from("schema_migrations.sql") }
  end

  def load_initial_data
    # we don't have the import.sql file therefore we load an initial clean data
    puts_step 'Load initial data'
    @connection.transaction { run_sql_commands_from("data.sql") }
  end

  def run_migrations
    puts_step 'Updating database schema'

    # Add Foreign key extensions
    ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ForeignKeysExtensions)
    ActiveRecord::SchemaDumper.send(:include, SchemaDumper)

    ActiveRecord::Migration.verbose = true
    @migrator.migrate
  end

  def import_domain
    puts_step 'Importing data from bananascrum.com'
    @connection.transaction do
      disable_foreign_key_checks { run_sql_commands_from('import.sql') }

      # update domain name and plan
      plan = Plan.find_by_name 'No limits'
      Domain.update_all :name => AppConfig.default_domain, :plan_id => plan.id
    end
  end

  def puts_step(text)
    puts("\n\n" + ('-' * 10) + ' ' + text + ' ' + ('-' * 10) + "\n\n")
  end

  def disable_foreign_key_checks(&block)
    @connection.execute('SET foreign_key_checks = 0')
    block.call
    @connection.execute('SET foreign_key_checks = 1')
  end

end

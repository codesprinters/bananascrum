class MysqlDumper
  def initialize(config)
    @config = config
  end

  def dump(file)
    system(find_cmd("mysqldump"), "--user=#{username}", "--password=#{password}",
      "--result-file=#{file}", database)
  end

  def restore(file)
    raise "Cannot restore, #{file} not found" unless File.exists? file
    system(find_cmd("mysql"), "--user=#{username}", "--password=#{password}",
      database, "--execute=source #{file}")
  end

  protected

  def username
    @config['username']
  end

  def password
    @config['password']
  end

  def database
    @config['database']
  end

  # Ripped from vendor/rails/railties/lib/commands/dbconsole.rb
  def find_cmd(*commands)
    dirs_on_path = ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
    commands += commands.map{|cmd| "#{cmd}.exe"} if RUBY_PLATFORM =~ /win32/
    commands.detect do |cmd|
      dirs_on_path.detect do |path|
        File.executable? File.join(path, cmd)
      end
    end || raise("Couldn't find database client: #{commands.join(', ')}. Check your $PATH and try again.")
  end
end

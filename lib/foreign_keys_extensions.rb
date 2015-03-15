module ForeignKeysExtensions

  unless defined?(ForeignKeyDefinition) 
    class ForeignKeyDefinition < Struct.new(:name, :table_name, :column_names, :references_table_name, :references_column_names, :on_update, :on_delete, :deferrable)
      ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :set_null => "SET NULL", :set_default => "SET DEFAULT", :no_action => "NO ACTION" }.freeze
  
      def to_dump
        dump = "add_foreign_key"
        dump << " #{table_name.inspect}, [#{column_names.collect{ |name| name.inspect }.join(', ')}]"
        dump << ", #{references_table_name.inspect}, [#{references_column_names.collect{ |name| name.inspect }.join(', ')}]"
        dump << ", :on_update => :#{on_update}" if on_update
        dump << ", :on_delete => :#{on_delete}" if on_delete
        dump << ", :deferrable => #{deferrable}" if deferrable
        dump << ", :name => #{name.inspect}" if name
        dump
      end
  
      def to_sql
        sql = name ? "CONSTRAINT #{name} " : ""
        sql << "FOREIGN KEY (#{Array(column_names).join(", ")}) REFERENCES #{references_table_name} (#{Array(references_column_names).join(", ")})"
        sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
        sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
        sql << " DEFERRABLE" if deferrable
        sql
      end
  
      alias :to_s :to_sql
    end
  
    def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
      foreign_key = ForeignKeyDefinition.new(options[:name], table_name, column_names, ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
      execute "ALTER TABLE #{table_name} ADD #{foreign_key}"
    end
  
    def remove_foreign_key(table_name, foreign_key_name)
      execute "ALTER TABLE #{table_name} DROP FOREIGN KEY #{foreign_key_name}"
    end
  
    def remove_foreign_keys(table_name, references_table_name)
      foreign_keys(table_name).each do |fk|
        remove_foreign_key table_name.to_sym, fk.name.to_sym if fk.references_table_name == references_table_name.to_s
      end
    end
  
    def foreign_keys(table_name, name = nil)
      results = execute("SHOW CREATE TABLE `#{table_name}`", name)
      foreign_keys = []
  
      results.each do |row|
        row['Create Table'].each do |line|
          if line =~ /^  CONSTRAINT [`"](.+?)[`"] FOREIGN KEY \([`"](.+?)[`"]\) REFERENCES [`"](.+?)[`"] \((.+?)\)( ON DELETE (.+?))?( ON UPDATE (.+?))?,?$/
            name = $1
            column_names = $2
            references_table_name = $3
            references_column_names = $4
            on_update = $8
            on_delete = $6
            on_update = on_update.downcase.gsub(' ', '_').to_sym if on_update
            on_delete = on_delete.downcase.gsub(' ', '_').to_sym if on_delete
  
            foreign_keys << ForeignKeyDefinition.new(name,
              table_name, column_names.gsub('`', '').split(', '),
              references_table_name, references_column_names.gsub('`', '').split(', '),
              on_update, on_delete)
          end
        end
      end
  
      return foreign_keys
    end
  end
end

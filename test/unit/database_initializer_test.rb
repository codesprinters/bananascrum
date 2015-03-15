require File.dirname(__FILE__) + '/../test_helper'

class DatabaseInitializerTest < ActiveSupport::TestCase

  def self.context_with_clean_database(&block)
    context 'with clean database' do
      setup do
        @initializer.expects(:clean_database?).at_least_once.returns(true)
      end

      merge_block(&block)
    end
  end

  def self.context_with_database(&block)
    context 'with database' do
      setup do
        @initializer.expects(:clean_database?).at_least_once.returns(false)
      end

      merge_block(&block)
    end
  end

  def self.context_with_pending_migrations(&block)
    context 'with pending migrations' do
      setup do
        @initializer.expects(:pending_migrations?).returns(true)
      end

      merge_block(&block)
    end
  end

  def self.context_with_imported_data(&block)
    context 'with imported data' do
      setup do
        @initializer.expects(:import_domain?).at_least_once.returns(true)
      end

      merge_block(&block)
    end
  end

  context 'a DatabaseInitializer instance' do
    setup do
      @connection = ActiveRecord::Base.connection
      @initializer = DatabaseInitializer.new(@connection)
    end

    context_with_clean_database do
      setup do
        @initializer.expects(:puts_step).with('Create database schema')
        @initializer.expects(:run_sql_commands_from).with('schema.sql')

        @initializer.expects(:puts_step).with('Load schema_migrations')
        @initializer.expects(:run_sql_commands_from).with('schema_migrations.sql')
      end
      
      context_with_pending_migrations do
        setup do
          @initializer.expects(:puts_step).with('Updating database schema')
          ActiveRecord::Migrator.any_instance.expects(:migrate)
        end
        
        context_with_imported_data do
          setup do
            @initializer.expects(:puts_step).with('Importing data from bananascrum.com')

            @initializer.expects(:run_sql_commands_from).never.with('data.sql')
            @initializer.expects(:run_sql_commands_from).with('import.sql')

            Domain.expects(:update_all)
          end
          
          should('load schema') { @initializer.run }
        end
      end
    end
  end

end

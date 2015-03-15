class RemoveTaskUserIdFromLogs < ActiveRecord::Migration
  def self.up
    foreign_keys('logs').each do |fk|
      remove_foreign_key :logs, fk.name.to_sym if fk.references_table_name == 'task_users'
    end
    remove_column :logs, :task_user_id
  end

  def self.down
    add_column :logs, :task_user_id, :integer
    add_foreign_key :logs, :task_user_id, :task_users, :id, :on_delete => :set_null
  end
end

class AddFirstTimeFlagToDomain < ActiveRecord::Migration
  def self.up
    add_column :domains, :first_time, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :domains, :first_time
  end
end

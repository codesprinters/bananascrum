class AddPendingToPlanChanges < ActiveRecord::Migration
  def self.up
    add_column(:plan_changes, :pending, :boolean, :default => true, :null => false)
  end

  def self.down
    remove_column(:plan_changes, :pending)
  end
end

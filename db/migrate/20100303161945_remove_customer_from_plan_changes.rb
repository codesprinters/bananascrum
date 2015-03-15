class RemoveCustomerFromPlanChanges < ActiveRecord::Migration
  def self.up
    remove_foreign_keys(:plan_changes, :customers)
    remove_column(:plan_changes, :customer_id)
  end

  def self.down
    add_column(:plan_changes, :customer_id, :integer, :null => false)
    add_foreign_key(:plan_changes, :customer_id, :customers, :id)
  end
end

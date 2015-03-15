class AddItemsLimitToPlans < ActiveRecord::Migration
  def self.up
    add_column(:plans, 'items_limit', :integer, :null => true)
    add_index(:plans, 'items_limit', :name => 'idx_items_limit')
  end

  def self.down
    remove_index(:plans, :name => 'idx_items_limit')
    remove_column(:plans, 'items_limit')
  end
end

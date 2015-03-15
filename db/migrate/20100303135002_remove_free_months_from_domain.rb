class RemoveFreeMonthsFromDomain < ActiveRecord::Migration
  def self.up
    remove_column(:domains, :free_months)
  end

  def self.down
    add_column(:domains, :free_months, :integer, :null => false, :default => 0)
  end
end

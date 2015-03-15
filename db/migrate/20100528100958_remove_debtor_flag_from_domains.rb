class RemoveDebtorFlagFromDomains < ActiveRecord::Migration
  def self.up
    remove_column :domains, :debtor
  end

  def self.down
    add_column :domains, :debtor, :boolean, :default => false
  end
end

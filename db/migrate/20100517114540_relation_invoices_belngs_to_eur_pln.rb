class RelationInvoicesBelngsToEurPln < ActiveRecord::Migration
  def self.up
    add_column :invoices, :eur_rate_id, :integer
    add_foreign_key :invoices, :eur_rate_id, :eur_rates, :id, :on_delete => :restrict
  end

  def self.down
    remove_foreing_keys :invoices, :eur_rates
    remove_column :invoices, :eur_rate_id
  end
end

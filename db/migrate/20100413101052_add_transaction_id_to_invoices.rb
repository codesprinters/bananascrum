class AddTransactionIdToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :transaction_id, :string
  end

  def self.down
    remove_column :invoices, :transaction_id
  end
end

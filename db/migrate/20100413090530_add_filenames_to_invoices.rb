class AddFilenamesToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :original_filename, :string
    add_column :invoices, :copy_filename, :string
  end

  def self.down
    remove_column :invoices, :original_filename
    remove_column :invoices, :copy_filename
  end
end

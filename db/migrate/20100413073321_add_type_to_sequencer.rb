class AddTypeToSequencer < ActiveRecord::Migration
  def self.up
    add_column :invoice_number_sequencers, :invoice_type, :string, :length => 10, :default => "trade", :null => false
    remove_index :invoice_number_sequencers, :name => "index_invoice_number_sequencers_on_year_and_month"
    add_index "invoice_number_sequencers", ["year", "month", "invoice_type"], :name => "index_invoice_number_sequencers_on_year_and_month", :unique => true
  end

  def self.down
    remove_index :invoice_number_sequencers, :name => "index_invoice_number_sequencers_on_year_and_month"
    remove_column  :invoice_number_sequencers, :invoice_type
    add_index "invoice_number_sequencers", ["year", "month"], :name => "index_invoice_number_sequencers_on_year_and_month", :unique => true
  end
end

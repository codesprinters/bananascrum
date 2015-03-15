class IntroduceDummyClassInCustomer < ActiveRecord::Migration  
  class Customer < ActiveRecord::Base; end;

  def self.up
    change_column :customers, :name, :string
    change_column :customers, :postcode, :string
    change_column :customers, :email, :string
    change_column :customers, :country, :string
    change_column :customers, :city, :string
    change_column :customers, :company, :boolean
    add_column :customers, :dummy, :boolean, :default => false
  end

  def self.down
    change_column :customers, :name, :string, :null => false
    change_column :customers, :postcode, :string, :null => false
    change_column :customers, :email, :string, :null => false
    change_column :customers, :country, :string, :null => false
    change_column :customers, :city, :string, :null => false
    change_column :customers, :company, :boolean, :null => false
    remove_column :customers, :dummy
  end
end

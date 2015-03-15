class AddPayPalProfileIdToCustomer < ActiveRecord::Migration
  def self.up
    add_column(:customers, :paypal_profile_id, :string, :null => true, :limit => 19)
    add_index(:customers, :paypal_profile_id, :unique => true)
  end

  def self.down
    remove_column(:customers, :paypal_profile_id)
  end
end

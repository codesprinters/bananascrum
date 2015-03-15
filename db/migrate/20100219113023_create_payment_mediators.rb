class CreatePaymentMediators < ActiveRecord::Migration
  def self.up
    create_table :payment_mediators do |t|
      t.integer :domain_id, :null => false, :on_delete => :cascade
      t.string :paypal_profile_id, :null => true, :limit => 19
      t.integer :rebilling_agreement_status, :null => true, :default => nil

      t.timestamps
    end
    
    remove_column(:customers, :paypal_profile_id)
    remove_column(:domains, :rebilling_agreement_status)
  end

  def self.down
    drop_table :payment_mediators

    add_column(:customers, :paypal_profile_id, :string, :null => true, :limit => 19)
    add_index(:customers, :paypal_profile_id, :unique => true)

    add_column(:domains, :rebilling_agreement_status, :integer, :null => true, :default => nil)
  end
end

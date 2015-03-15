class RemovePaymentMediator < ActiveRecord::Migration
  def self.up
    drop_table(:payment_mediators)

    add_column(:domains, :billing_profile_id, :string, :null => true, :limit => 19)
    add_index(:domains, :billing_profile_id, :unique => true)
    add_column(:domains, :billing_agreement_status, :string, :null => true, :limit => 16)
  end

  def self.down
    create_table :payment_mediators do |t|
      t.integer :domain_id, :null => false, :on_delete => :cascade
      t.string :paypal_profile_id, :null => true, :limit => 19
      t.integer :rebilling_agreement_status, :null => true, :default => nil

      t.timestamps
    end

    remove_column(:domains, :billing_profile_id)
    remove_column(:domains, :billing_agreement_status)
  end
end

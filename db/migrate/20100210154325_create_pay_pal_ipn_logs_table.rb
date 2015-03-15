class CreatePayPalIpnLogsTable < ActiveRecord::Migration
  def self.up
    create_table(:paypal_ipn_logs) do |t|
      t.integer :domain_id
      t.integer :plan_id
      t.integer :payment_id

      t.string :recurring_payment_id, :limit => 19
      t.text :raw_post, :null => false

      t.datetime :created_at
    end

    add_foreign_key(:paypal_ipn_logs, :domain_id, :domains, :id, :on_delete => :set_null)
    add_foreign_key(:paypal_ipn_logs, :plan_id, :plans, :id, :on_delete => :set_null)
    add_foreign_key(:paypal_ipn_logs, :payment_id, :payments, :id, :on_delete => :set_null)
  end

  def self.down
    drop_table(:paypal_ipn_logs)
  end
end

class ExtendPaypalIpnLog < ActiveRecord::Migration
  def self.up
    change_table(:paypal_ipn_logs) do |t|
      t.boolean :success, :null => false, :default => false
      t.string :message
    end
  end

  def self.down
    change_table(:paypal_ipn_logs) do |t|
      t.remove :success
      t.remove :message
    end
  end
end

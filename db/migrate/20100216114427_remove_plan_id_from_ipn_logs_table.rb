class RemovePlanIdFromIpnLogsTable < ActiveRecord::Migration
  def self.up
    foreign_keys('paypal_ipn_logs').each do |fk|
      remove_foreign_key :paypal_ipn_logs, fk.name.to_sym if fk.references_table_name == 'plans'
    end
    remove_column(:paypal_ipn_logs, :plan_id)
  end

  def self.down
    add_column(:paypal_ipn_logs, :plan_id, :integer)
    add_foreign_key(:paypal_ipn_logs, :plan_id, :plans, :id, :on_delete => :set_null)
  end
end

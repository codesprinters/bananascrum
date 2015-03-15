class AddMannerOfPaymentToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :manner_of_payment, :string, :default => "PayPal", :nil => false
  end

  def self.down
    remove_column :payments, :manner_of_payment
  end
end

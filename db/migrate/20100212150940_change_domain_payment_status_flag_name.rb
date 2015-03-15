class ChangeDomainPaymentStatusFlagName < ActiveRecord::Migration
  def self.up
    rename_column(:domains, :first_payment_status, :rebilling_agreement_status)
  end

  def self.down
    rename_column(:domains, :rebilling_agreement_status, :first_payment_status)
  end
end

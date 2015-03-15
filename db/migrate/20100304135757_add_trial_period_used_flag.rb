class AddTrialPeriodUsedFlag < ActiveRecord::Migration
  def self.up
    add_column(:domains, :trial_period_used, :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column(:domains, :trial_period_used)
  end
end

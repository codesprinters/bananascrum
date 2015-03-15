class CreateDateFormatPreference < ActiveRecord::Migration
  def self.up
    add_column(:users, :date_format_preference, :string, :default => 'YYYY-MM-DD', :null => false)
  end

  def self.down
    remove_column(:users, :date_format_preference)
  end
end

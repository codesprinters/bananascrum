class AddWarningToDomain < ActiveRecord::Migration
  def self.up
    add_column :domains, :warning, :string
  end

  def self.down
    remove_column :domains, :warning
  end
end

class ChangeDefaultTagColor < ActiveRecord::Migration
  def self.up
    change_column_default(:tags, :color_no, 21)
  end

  def self.down
    change_column_default(:tags, :color_no, 1)
  end
end

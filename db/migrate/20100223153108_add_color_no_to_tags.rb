class AddColorNoToTags < ActiveRecord::Migration
  def self.up
    add_column(:tags, 'color_no', :integer, :null => false, :default => 1)
    add_index(:tags, 'color_no', :name => 'idx_tag_color_no')
  end

  def self.down
    remove_index(:tags, :name => 'idx_tag_color_no')
    remove_column(:tags, 'color_no')
  end
end

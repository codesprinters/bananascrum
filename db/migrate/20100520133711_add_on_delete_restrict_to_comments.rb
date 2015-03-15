class AddOnDeleteRestrictToComments < ActiveRecord::Migration
  def self.up
    remove_foreign_keys(:comments, :users)
    add_foreign_key(:comments, :user_id, :users, :id, :on_delete => :restrict, :on_update => :restrict)
  end

  def self.down
    remove_foreign_keys(:comments, :users)
    add_foreign_key(:comments, :user_id, :users, :id, :on_delete => :cascade, :on_update => :cascade)
  end
end

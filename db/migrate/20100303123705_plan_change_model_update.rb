class PlanChangeModelUpdate < ActiveRecord::Migration
  def self.up
    self.clean_user_keys
    add_foreign_key(:plan_changes, :user_id, :users, :id, :on_delete => :set_null)
  end

  def self.down
    self.clean_user_keys
    add_foreign_key(:plan_changes, :user_id, :users, :id, :on_delete => :cascade)
  end

  protected
  def self.clean_user_keys
    foreign_keys(:plan_changes).each do |fk|
      remove_foreign_key :plan_changes, fk.name.to_sym if fk.references_table_name == 'users'
    end
  end
end

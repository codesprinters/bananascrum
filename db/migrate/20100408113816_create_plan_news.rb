class CreatePlanNews < ActiveRecord::Migration
  def self.up
    create_table :plan_news do |t|
      t.integer :plan_id, :null => false
      t.integer :news_id, :null => false

      t.timestamps
    end
    
    add_foreign_key(:plan_news, :plan_id, :plans, :id, :on_delete => :cascade)
    add_foreign_key(:plan_news, :news_id, :news, :id, :on_delete => :cascade)
  end

  def self.down
    remove_foreign_keys(:plan_news, :plans)
    remove_foreign_keys(:plan_news, :news)
    drop_table :plan_news
  end
end

class CreateIndexCardLogs < ActiveRecord::Migration
  def self.up
    create_table :index_card_logs do |t|
      t.integer :id, :null => false
      t.integer :domain_id, :null => false
      t.integer :collection_size, :null => false
      t.string :context
      t.string :contents, :null => false
      t.timestamps
    end

    add_foreign_key(:index_card_logs, :domain_id, :domains, :id, :on_delete => :cascade)

  end

  def self.down
    drop_table :index_card_logs
  end
end

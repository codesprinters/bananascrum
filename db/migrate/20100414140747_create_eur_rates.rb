class CreateEurRates < ActiveRecord::Migration
  def self.up
    create_table :eur_rates do |t|
      t.decimal :rate, :precision => 6, :scale => 4, :null => false
      t.date :publish_date, :null => false
    end
  end

  def self.down
    drop_table :eur_rates
  end
end

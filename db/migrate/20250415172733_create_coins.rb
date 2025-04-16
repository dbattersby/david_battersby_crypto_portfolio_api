class CreateCoins < ActiveRecord::Migration[7.2]
  def change
    create_table :coins do |t|
      t.string :symbol
      t.string :name
      t.decimal :current_price, precision: 18, scale: 8
      t.datetime :last_updated

      t.timestamps
    end

    add_index :coins, :symbol, unique: true
  end
end

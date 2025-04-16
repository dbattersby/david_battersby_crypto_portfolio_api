class AddPriceChange24hToCoin < ActiveRecord::Migration[7.2]
  def change
    add_column :coins, :price_change_24h, :decimal, precision: 10, scale: 2
  end
end

class CreateAssets < ActiveRecord::Migration[7.2]
  def change
    create_table :assets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol
      t.string :name
      t.decimal :quantity
      t.decimal :purchase_price

      t.timestamps
    end
  end
end

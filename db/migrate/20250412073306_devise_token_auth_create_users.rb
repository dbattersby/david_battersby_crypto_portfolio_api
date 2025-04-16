class DeviseTokenAuthCreateUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users do |t|
      ## Required
      t.string :provider, null: false, default: "email"
      t.string :uid, null: false, default: ""

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## User Info
      t.string :name
      t.string :nickname
      t.string :image

      ## Tokens
      t.json :tokens

      ## Additional
      t.boolean :allow_password_change, default: false
    end

    add_index :users, [ :uid, :provider ], unique: true
    add_index :users, :confirmation_token, unique: true
  end
end

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :phone_number
      t.string :password_digest
      t.string :chain_key
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :facebook_id

      t.timestamps
    end
  end
end

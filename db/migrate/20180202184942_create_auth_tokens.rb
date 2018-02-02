class CreateAuthTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :auth_tokens do |t|
      t.references :user, foreign_key: true
      t.string :token
      t.string :device

      t.timestamps
    end
  end
end

class CreateChainAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :chain_assets do |t|
      t.string :alias
      t.string :definition

      t.timestamps
    end
  end
end

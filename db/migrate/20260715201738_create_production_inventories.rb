class CreateProductionInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :production_inventories do |t|
      t.references :production, null: false, foreign_key: true
      t.integer :helmets, null: false, default: 0
      t.integer :locks, null: false, default: 0
      t.timestamps
    end
  end
end

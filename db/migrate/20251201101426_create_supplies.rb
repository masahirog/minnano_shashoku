class CreateSupplies < ActiveRecord::Migration[7.1]
  def change
    create_table :supplies do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.string :category, null: false
      t.string :unit, null: false
      t.integer :reorder_point
      t.text :storage_guideline
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :supplies, :sku, unique: true
    add_index :supplies, :category
  end
end

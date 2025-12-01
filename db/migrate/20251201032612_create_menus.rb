class CreateMenus < ActiveRecord::Migration[7.1]
  def change
    create_table :menus do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :price_per_meal, null: false, default: 649
      t.boolean :is_active, default: true
      t.string :photo_url

      t.timestamps
    end
  end
end

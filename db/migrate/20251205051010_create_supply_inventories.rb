class CreateSupplyInventories < ActiveRecord::Migration[7.1]
  def change
    create_table :supply_inventories do |t|
      t.references :supply, null: false, foreign_key: true
      t.string :location_type
      t.bigint :location_id
      t.date :inventory_date, null: false
      t.decimal :theoretical_quantity, precision: 10, scale: 2
      t.decimal :actual_quantity, precision: 10, scale: 2
      t.decimal :difference, precision: 10, scale: 2
      t.text :notes
      t.references :admin_user, foreign_key: true

      t.timestamps
    end
  end
end

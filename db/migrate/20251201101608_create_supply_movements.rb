class CreateSupplyMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :supply_movements do |t|
      t.references :supply, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.references :from_location, polymorphic: true, null: true
      t.references :to_location, polymorphic: true, null: true
      t.date :movement_date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :supply_movements, :movement_type
    add_index :supply_movements, :movement_date
  end
end

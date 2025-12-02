class CreateSupplyStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :supply_stocks do |t|
      t.references :supply, null: false, foreign_key: true
      t.references :location, polymorphic: true, null: true
      t.string :location_name
      t.string :location_type_detail
      t.decimal :quantity, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :physical_count, precision: 10, scale: 2
      t.datetime :last_updated_at

      t.timestamps
    end

    add_index :supply_stocks, [:supply_id, :location_type, :location_id, :location_name],
              name: 'index_supply_stocks_on_supply_and_location', unique: true
  end
end

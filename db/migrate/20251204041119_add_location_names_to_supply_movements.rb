class AddLocationNamesToSupplyMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :supply_movements, :from_location_name, :string
    add_column :supply_movements, :to_location_name, :string
  end
end

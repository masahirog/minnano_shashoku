class AddStatusToSupplyMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :supply_movements, :status, :string, default: '確定', null: false
  end
end

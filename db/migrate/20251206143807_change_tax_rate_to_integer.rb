class ChangeTaxRateToInteger < ActiveRecord::Migration[7.1]
  def up
    change_column :menus, :tax_rate, :integer, default: 8
    change_column :order_items, :tax_rate, :integer, default: 8
  end

  def down
    change_column :menus, :tax_rate, :decimal, precision: 5, scale: 2, default: 8
    change_column :order_items, :tax_rate, :decimal, precision: 5, scale: 2, default: 8
  end
end

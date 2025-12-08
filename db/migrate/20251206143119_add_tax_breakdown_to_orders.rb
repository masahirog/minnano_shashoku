class AddTaxBreakdownToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :tax_8_percent, :decimal, precision: 10, scale: 2, default: 0
    add_column :orders, :tax_10_percent, :decimal, precision: 10, scale: 2, default: 0
    add_column :orders, :delivery_fee_tax, :decimal, precision: 10, scale: 2, default: 0
  end
end

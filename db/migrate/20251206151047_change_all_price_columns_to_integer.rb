class ChangeAllPriceColumnsToInteger < ActiveRecord::Migration[7.1]
  def up
    # order_items テーブル
    change_column :order_items, :unit_price, :integer, null: false
    change_column :order_items, :subtotal, :integer, null: false

    # orders テーブル
    change_column :orders, :discount_amount, :integer, default: 0
    change_column :orders, :subtotal, :integer
    change_column :orders, :tax, :integer
    change_column :orders, :delivery_fee, :integer, default: 0
    change_column :orders, :total_price, :integer
    change_column :orders, :tax_8_percent, :integer, default: 0
    change_column :orders, :tax_10_percent, :integer, default: 0
    change_column :orders, :delivery_fee_tax, :integer, default: 0

    # invoices テーブル (既にinteger型なのでスキップ)
  end

  def down
    # order_items テーブル
    change_column :order_items, :unit_price, :decimal, precision: 10, scale: 2, null: false
    change_column :order_items, :subtotal, :decimal, precision: 10, scale: 2, null: false

    # orders テーブル
    change_column :orders, :discount_amount, :decimal, precision: 10, scale: 2, default: 0.0
    change_column :orders, :subtotal, :decimal, precision: 10, scale: 2
    change_column :orders, :tax, :decimal, precision: 10, scale: 2
    change_column :orders, :delivery_fee, :decimal, precision: 10, scale: 2, default: 0.0
    change_column :orders, :total_price, :decimal, precision: 10, scale: 2
    change_column :orders, :tax_8_percent, :decimal, precision: 10, scale: 2, default: 0.0
    change_column :orders, :tax_10_percent, :decimal, precision: 10, scale: 2, default: 0.0
    change_column :orders, :delivery_fee_tax, :decimal, precision: 10, scale: 2, default: 0.0

    # invoices テーブル (スキップ)
  end
end

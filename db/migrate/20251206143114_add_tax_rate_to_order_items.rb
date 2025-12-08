class AddTaxRateToOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_column :order_items, :tax_rate, :decimal, precision: 5, scale: 2, default: 10
  end
end

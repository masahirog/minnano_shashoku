class AddDiscountToOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_column :order_items, :discount_type, :string
    add_column :order_items, :discount_value, :decimal, precision: 10, scale: 2
    add_column :order_items, :discount_amount, :decimal, precision: 10, scale: 2, default: 0
  end
end

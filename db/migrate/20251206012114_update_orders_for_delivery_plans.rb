class UpdateOrdersForDeliveryPlans < ActiveRecord::Migration[7.1]
  def change
    # restaurant_idをoptionalに変更
    change_column_null :orders, :restaurant_id, true

    # 削除するカラム
    remove_column :orders, :default_meal_count, :integer
    remove_column :orders, :confirmed_meal_count, :integer
    remove_column :orders, :menu_id, :bigint
    remove_column :orders, :second_menu_id, :bigint
    remove_column :orders, :delivery_group, :integer
    remove_column :orders, :delivery_priority, :integer
    remove_column :orders, :options, :jsonb

    # 追加するカラム
    add_column :orders, :total_meal_count, :integer
    add_column :orders, :subtotal, :decimal, precision: 10, scale: 2
    add_column :orders, :tax, :decimal, precision: 10, scale: 2
    add_column :orders, :delivery_fee, :decimal, precision: 10, scale: 2
    add_column :orders, :total_price, :decimal, precision: 10, scale: 2
    add_column :orders, :memo, :text
  end
end

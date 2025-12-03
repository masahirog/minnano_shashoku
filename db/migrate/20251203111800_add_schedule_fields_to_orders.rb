class AddScheduleFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :recurring_order, null: true, foreign_key: true

    add_column :orders, :menu_confirmed, :boolean, default: false
    add_column :orders, :meal_count_confirmed, :boolean, default: false
    add_column :orders, :confirmation_deadline, :datetime

    add_index :orders, :scheduled_date unless index_exists?(:orders, :scheduled_date)
  end
end

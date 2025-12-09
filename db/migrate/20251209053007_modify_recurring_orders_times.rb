class ModifyRecurringOrdersTimes < ActiveRecord::Migration[7.1]
  def change
    add_column :recurring_orders, :collection_time, :time
    remove_column :recurring_orders, :pickup_time, :time
  end
end

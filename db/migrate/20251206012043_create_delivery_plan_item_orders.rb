class CreateDeliveryPlanItemOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_plan_item_orders do |t|
      t.references :delivery_plan_item, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :action_role, null: false

      t.timestamps
    end

    add_index :delivery_plan_item_orders, [:delivery_plan_item_id, :order_id],
              unique: true,
              name: 'index_delivery_plan_item_orders_on_item_and_order'
  end
end

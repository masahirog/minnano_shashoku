class DropDeliveryRoutesAndPushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    drop_table :delivery_routes, if_exists: true do |t|
      t.bigint :delivery_assignment_id, null: false
      t.bigint :delivery_user_id, null: false
      t.datetime :recorded_at, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.decimal :accuracy
      t.decimal :speed
      t.timestamps
    end

    drop_table :push_subscriptions, if_exists: true do |t|
      t.string :subscribable_type, null: false
      t.bigint :subscribable_id, null: false
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.boolean :is_active, default: true
      t.string :user_agent
      t.timestamps
    end
  end
end

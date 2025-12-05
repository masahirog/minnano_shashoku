class CreatePushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :push_subscriptions do |t|
      t.string :subscribable_type, null: false
      t.bigint :subscribable_id, null: false
      t.text :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.text :user_agent
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :push_subscriptions, [:subscribable_type, :subscribable_id], name: 'index_push_subscriptions_on_subscribable'
    add_index :push_subscriptions, :endpoint, unique: true
    add_index :push_subscriptions, :is_active
  end
end

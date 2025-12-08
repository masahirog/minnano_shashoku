class CreateDeliveryPlanItems < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_plan_items do |t|
      t.references :delivery_plan, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :action_type, null: false
      t.string :location_type
      t.bigint :location_id
      t.time :scheduled_time
      t.time :actual_time
      t.string :status, null: false, default: 'pending'
      t.integer :meal_count
      t.jsonb :supplies_info, default: {}
      t.text :notes
      t.string :photo_url
      t.string :completed_by
      t.datetime :completed_at

      t.timestamps
    end

    add_index :delivery_plan_items, [:delivery_plan_id, :sequence]
    add_index :delivery_plan_items, [:location_type, :location_id]
    add_index :delivery_plan_items, :status
  end
end

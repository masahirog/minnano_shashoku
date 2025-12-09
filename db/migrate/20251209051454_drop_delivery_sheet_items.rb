class DropDeliverySheetItems < ActiveRecord::Migration[7.1]
  def change
    drop_table :delivery_sheet_items do |t|
      t.bigint :order_id, null: false
      t.bigint :driver_id
      t.date :delivery_date, null: false
      t.integer :sequence, null: false
      t.string :action_type, null: false
      t.string :delivery_type
      t.time :scheduled_time
      t.string :location_type
      t.string :location_name
      t.text :address
      t.string :phone
      t.boolean :has_setup, default: false
      t.text :meal_info
      t.text :supplies_info
      t.text :notes
      t.string :photo_url
      t.timestamps

      t.index [:delivery_date, :sequence], name: "index_delivery_sheet_items_on_delivery_date_and_sequence"
      t.index :driver_id, name: "index_delivery_sheet_items_on_driver_id"
      t.index :order_id, name: "index_delivery_sheet_items_on_order_id"
    end
  end
end

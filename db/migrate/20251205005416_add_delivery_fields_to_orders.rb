class AddDeliveryFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :delivery_notes, :text
    add_column :orders, :recipient_name, :string
    add_column :orders, :recipient_phone, :string
    add_column :orders, :delivery_address, :text
  end
end

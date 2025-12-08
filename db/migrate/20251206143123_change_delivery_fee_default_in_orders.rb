class ChangeDeliveryFeeDefaultInOrders < ActiveRecord::Migration[7.1]
  def change
    change_column_default :orders, :delivery_fee, from: nil, to: 0
  end
end

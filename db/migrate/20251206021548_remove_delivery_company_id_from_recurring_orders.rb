class RemoveDeliveryCompanyIdFromRecurringOrders < ActiveRecord::Migration[7.1]
  def change
    remove_column :recurring_orders, :delivery_company_id, :integer
  end
end

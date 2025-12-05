class AddApiFieldsToDeliveryCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :delivery_companies, :api_enabled, :boolean, default: false, null: false
    add_column :delivery_companies, :api_key, :string
    add_column :delivery_companies, :service_area, :json

    add_index :delivery_companies, :api_key, unique: true
  end
end

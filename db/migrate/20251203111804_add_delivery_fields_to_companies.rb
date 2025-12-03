class AddDeliveryFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :delivery_time_preferred, :time  # 希望納品時間
    add_column :companies, :delivery_time_earliest, :time  # 納品可能最早
    add_column :companies, :delivery_time_latest, :time  # 納品可能最遅
    add_column :companies, :meal_count_min, :integer  # 最小食数
    add_column :companies, :meal_count_max, :integer  # 最大食数
  end
end

class AddFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :delivery_day_of_week, :string
    add_column :companies, :has_setup, :boolean
    add_column :companies, :digital_signage_id, :string
    add_column :companies, :first_delivery_date, :date
    add_column :companies, :discount_campaign_end_date, :date
    add_column :companies, :trial_billable, :boolean
    add_column :companies, :trial_free_meal_count, :integer
    add_column :companies, :trial_date, :date
    add_column :companies, :employee_burden_enabled, :boolean
    add_column :companies, :employee_burden_amount, :integer
    add_column :companies, :delivery_time_goal, :string
    add_column :companies, :pickup_time_goal, :string
    add_column :companies, :delivery_notes, :text
    add_column :companies, :pickup_notes, :text
    add_column :companies, :monthly_fee_type, :string
    add_column :companies, :initial_fee_amount, :integer
    add_column :companies, :delivery_fee_campaign_end_date, :date
    add_column :companies, :delivery_fee_discount, :integer
    add_column :companies, :remote_delivery_fee, :integer
    add_column :companies, :special_delivery_fee, :integer
  end
end

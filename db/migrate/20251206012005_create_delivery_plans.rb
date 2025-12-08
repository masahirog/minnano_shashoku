class CreateDeliveryPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_plans do |t|
      t.references :delivery_company, null: false, foreign_key: true
      t.references :driver, foreign_key: { to_table: :delivery_users }
      t.date :delivery_date, null: false
      t.string :status, null: false, default: 'draft'
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes

      t.timestamps
    end

    add_index :delivery_plans, :delivery_date
    add_index :delivery_plans, [:delivery_date, :delivery_company_id]
    add_index :delivery_plans, :status
  end
end

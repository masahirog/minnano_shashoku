class CreateDeliveryAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_assignments do |t|
      t.references :order, null: false, foreign_key: true, index: {unique: true}
      t.references :delivery_user, null: false, foreign_key: true
      t.references :delivery_company, null: false, foreign_key: true
      t.date :scheduled_date, null: false
      t.time :scheduled_time
      t.integer :sequence_number
      t.string :status, null: false, default: 'pending'
      t.datetime :assigned_at

      t.timestamps
    end

    add_index :delivery_assignments, :scheduled_date
    add_index :delivery_assignments, :status
    add_index :delivery_assignments, [:delivery_user_id, :scheduled_date, :status], name: 'index_delivery_assignments_on_user_date_status'
  end
end

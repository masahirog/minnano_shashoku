class CreateDeliveryReports < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_reports do |t|
      t.references :delivery_assignment, null: false, foreign_key: true, index: {unique: true}
      t.references :delivery_user, null: false, foreign_key: true
      t.string :report_type, null: false, default: 'completed'
      t.datetime :started_at
      t.datetime :completed_at
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.text :notes
      t.string :issue_type
      t.json :photos
      t.text :signature_data

      t.timestamps
    end

    add_index :delivery_reports, :report_type
    add_index :delivery_reports, :completed_at
  end
end

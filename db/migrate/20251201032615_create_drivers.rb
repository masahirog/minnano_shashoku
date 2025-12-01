class CreateDrivers < ActiveRecord::Migration[7.1]
  def change
    create_table :drivers do |t|
      t.references :delivery_company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

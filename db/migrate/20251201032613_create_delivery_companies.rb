class CreateDeliveryCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_companies do |t|
      t.string :name, null: false
      t.string :contact_person
      t.string :phone
      t.string :email
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end

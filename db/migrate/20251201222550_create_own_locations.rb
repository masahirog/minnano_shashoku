class CreateOwnLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :own_locations do |t|
      t.string :name
      t.string :location_type
      t.string :address
      t.string :phone
      t.boolean :is_active

      t.timestamps
    end
  end
end

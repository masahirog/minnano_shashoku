class CreateDeliveryRoutes < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_routes do |t|
      t.references :delivery_assignment, null: false, foreign_key: true
      t.references :delivery_user, null: false, foreign_key: true
      t.datetime :recorded_at, null: false
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.decimal :accuracy, precision: 5, scale: 2
      t.decimal :speed, precision: 5, scale: 2

      t.timestamps
    end

    add_index :delivery_routes, :recorded_at
  end
end

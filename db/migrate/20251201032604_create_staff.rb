class CreateStaff < ActiveRecord::Migration[7.1]
  def change
    create_table :staff do |t|
      t.string :name, null: false
      t.string :email
      t.string :role

      t.timestamps
    end
  end
end

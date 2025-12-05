class CreateDeliveryUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :name, null: false
      t.string :phone
      t.string :role, null: false, default: 'driver'
      t.references :delivery_company, null: false, foreign_key: true
      t.boolean :is_active, null: false, default: true
      t.datetime :last_sign_in_at

      # Devise trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      # Devise recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      # Devise rememberable
      t.datetime :remember_created_at

      t.timestamps
    end

    add_index :delivery_users, :email, unique: true
    add_index :delivery_users, :is_active
    add_index :delivery_users, :reset_password_token, unique: true
  end
end

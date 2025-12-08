class AddDetailsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :phone, :string
    add_column :admin_users, :employee_number, :string
  end
end

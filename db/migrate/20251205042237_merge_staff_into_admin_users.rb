class MergeStaffIntoAdminUsers < ActiveRecord::Migration[7.1]
  def up
    # Step 1: AdminUserテーブルにカラムを追加
    add_column :admin_users, :name, :string
    add_column :admin_users, :role, :string
    add_column :admin_users, :is_login_enabled, :boolean, default: true, null: false

    # Step 2: 外部キー制約を一時削除
    remove_foreign_key :companies, :staff if foreign_key_exists?(:companies, :staff)
    remove_foreign_key :restaurants, :staff if foreign_key_exists?(:restaurants, :staff)

    # Step 3: StaffデータをAdminUserに移行
    staff_to_admin_user_mapping = {}

    execute("SELECT * FROM staff ORDER BY id").each do |staff_record|
      # AdminUserレコードを作成（ログイン不可）
      result = execute(<<-SQL)
        INSERT INTO admin_users (email, encrypted_password, name, role, is_login_enabled, created_at, updated_at)
        VALUES (
          '#{staff_record['email'] || "staff_#{staff_record['id']}@shashoku.com"}',
          '#{Devise::Encryptor.digest(AdminUser, SecureRandom.hex(32))}',
          '#{staff_record['name'].gsub("'", "''")}',
          '#{staff_record['role']&.gsub("'", "''") || ''}',
          false,
          NOW(),
          NOW()
        )
        RETURNING id
      SQL

      admin_user_id = result.first['id'].to_i
      staff_to_admin_user_mapping[staff_record['id'].to_i] = admin_user_id
      puts "Migrated Staff ID:#{staff_record['id']} -> AdminUser ID:#{admin_user_id} (#{staff_record['name']})"
    end

    # Step 4: companies.staff_idとrestaurants.staff_idを更新
    staff_to_admin_user_mapping.each do |staff_id, admin_user_id|
      execute("UPDATE companies SET staff_id = #{admin_user_id} WHERE staff_id = #{staff_id}")
      execute("UPDATE restaurants SET staff_id = #{admin_user_id} WHERE staff_id = #{staff_id}")
    end

    # Step 5: staff_idカラムの名前をadmin_user_idに変更
    rename_column :companies, :staff_id, :admin_user_id
    rename_column :restaurants, :staff_id, :admin_user_id

    # Step 6: 新しい外部キー制約を追加
    add_foreign_key :companies, :admin_users
    add_foreign_key :restaurants, :admin_users

    # Step 7: staffテーブルを削除
    drop_table :staff

    puts "Migration completed: #{staff_to_admin_user_mapping.size} staff records merged into admin_users"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

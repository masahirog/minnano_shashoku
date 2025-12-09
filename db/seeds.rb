# frozen_string_literal: true

puts "seedデータ作成開始..."

# 既存データをクリア
AdminUser.destroy_all

# =====================================================
# 管理者ユーザー
# =====================================================
admin_users_data = [
  { name: '齋藤', email: 'saito@example.com' },
  { name: '熊本', email: 'kumamoto@example.com' },
  { name: '服部', email: 'hattori@example.com' },
  { name: '片山', email: 'katayama@example.com' },
  { name: '榎本', email: 'enomoto@example.com' },
  { name: '山下', email: 'yamashita@example.com' }
]

admin_users_data.each do |user_data|
  admin = AdminUser.create!(
    email: user_data[:email],
    password: 'password',
    password_confirmation: 'password',
    name: user_data[:name]
  )
  puts "管理者ユーザー作成: #{admin.name} (#{admin.email})"
end

puts "\n=========================================="
puts "seedデータ作成完了！"
puts "=========================================="
puts "AdminUser: #{AdminUser.count}件"
puts "=========================================="
puts "ログイン情報: 各ユーザーのメールアドレス / password"
puts "  - saito@example.com"
puts "  - kumamoto@example.com"
puts "  - hattori@example.com"
puts "  - katayama@example.com"
puts "  - enomoto@example.com"
puts "  - yamashita@example.com"
puts "=========================================="

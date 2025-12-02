# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 既存データをクリア（開発環境のみ）
if Rails.env.development?
  puts "既存データをクリア中..."
  DeliverySheetItem.destroy_all
  Order.destroy_all
  Menu.destroy_all
  SupplyMovement.destroy_all
  SupplyStock.destroy_all
  Supply.destroy_all
  Driver.destroy_all
  DeliveryCompany.destroy_all
  Restaurant.destroy_all
  Company.destroy_all
  OwnLocation.destroy_all
  Staff.destroy_all
  AdminUser.destroy_all
end

puts "seedデータ作成開始..."

# 管理者ユーザー
admin = AdminUser.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.password_confirmation = 'password'
end
puts "管理者ユーザー作成: #{admin.email}"

# スタッフ
staffs = []
['山田太郎', '佐藤花子', '鈴木一郎', '田中美咲', '高橋健二'].each do |name|
  staff = Staff.create!(
    name: name,
    email: "#{name.tr('ぁ-ん', 'a-z')}@shashoku.com",
    role: ['営業', 'カスタマーサポート', 'マネージャー'].sample
  )
  staffs << staff
  puts "スタッフ作成: #{staff.name}"
end

# 自社拠点（みんなの食堂）
own_locations = []
[
  { name: '本社倉庫', location_type: '倉庫', address: '東京都港区虎ノ門1-1-1' },
  { name: '虎ノ門本社', location_type: 'オフィス', address: '東京都港区虎ノ門1-1-2' },
  { name: '第二倉庫', location_type: '倉庫', address: '東京都江東区豊洲2-1-1' },
  { name: '品川営業所', location_type: 'オフィス', address: '東京都品川区東品川3-1-1' }
].each do |location_data|
  location = OwnLocation.create!(
    name: location_data[:name],
    location_type: location_data[:location_type],
    address: location_data[:address],
    phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    is_active: true
  )
  own_locations << location
  puts "自社拠点作成: #{location.name}"
end

# 配送会社
delivery_companies = []
['東京配送サービス', '関東運輸', '首都圏デリバリー'].each do |name|
  dc = DeliveryCompany.create!(
    name: name,
    contact_person: ['山田', '佐藤', '鈴木'].sample + '配送責任者',
    email: "#{name.tr('ぁ-ん', 'a-z')}@delivery.com",
    phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    is_active: true
  )
  delivery_companies << dc
  puts "配送会社作成: #{dc.name}"
end

# ドライバー
drivers = []
delivery_companies.each do |dc|
  ['A', 'B', 'C'].each do |suffix|
    driver = Driver.create!(
      delivery_company: dc,
      name: "#{dc.name[0..1]}ドライバー#{suffix}",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      is_active: true
    )
    drivers << driver
    puts "ドライバー作成: #{driver.name}"
  end
end

# 導入企業
companies = []
[
  { name: 'テック株式会社', formal: '株式会社テック', status: '契約中' },
  { name: 'サンプル商事', formal: 'サンプル商事株式会社', status: '契約中' },
  { name: 'ABC工業', formal: 'ABC工業株式会社', status: '契約中' },
  { name: 'デジタルソリューションズ', formal: '株式会社デジタルソリューションズ', status: 'トライアル' },
  { name: 'グリーン物産', formal: 'グリーン物産株式会社', status: '契約中' }
].each do |company_data|
  company = Company.create!(
    name: company_data[:name],
    formal_name: company_data[:formal],
    staff: staffs.sample,
    contract_status: company_data[:status],
    contact_person: ['総務部', '人事部', '管理部'].sample + '担当者',
    contact_phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    contact_email: "contact@#{company_data[:name].tr('ぁ-ん', 'a-z')}.co.jp",
    default_meal_count: [10, 15, 20, 25, 30].sample,
    delivery_day_of_week: ['月,水,金', '火,木', '月,水,金', '毎日'].sample,
    has_setup: true,
    trial_billable: company_data[:status] == 'トライアル',
    employee_burden_enabled: [true, false].sample,
    employee_burden_amount: [200, 300, 400, 500].sample
  )
  companies << company
  puts "導入企業作成: #{company.name}"
end

# 飲食店
restaurants = []
[
  { name: '和食処 さくら', genre: '和食' },
  { name: 'イタリアンキッチン ベラ', genre: 'イタリアン' },
  { name: '中華料理 龍門', genre: '中華' },
  { name: 'カフェ&ダイニング オリーブ', genre: '洋食' },
  { name: '寿司割烹 海', genre: '寿司' },
  { name: 'フレンチビストロ ル・ソレイユ', genre: 'フレンチ' },
  { name: '焼肉ダイニング 牛角', genre: '焼肉' },
  { name: 'タイ料理 バンコク', genre: 'エスニック' },
  { name: 'パスタ工房 ポモドーロ', genre: 'イタリアン' },
  { name: '定食屋 まごころ', genre: '定食' }
].each do |restaurant_data|
  restaurant = Restaurant.create!(
    name: restaurant_data[:name],
    staff: staffs.sample,
    genre: restaurant_data[:genre],
    contract_status: '契約中',
    max_capacity: [50, 80, 100, 120, 150].sample,
    contact_person: 'オーナー',
    contact_phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    contact_email: "#{restaurant_data[:name].tr('ぁ-ん', 'a-z')}@restaurant.jp",
    supplier_code: "R#{sprintf('%04d', restaurants.length + 1)}"
  )
  restaurants << restaurant
  puts "飲食店作成: #{restaurant.name}"
end

# メニュー
menus = []
restaurants.each do |restaurant|
  menu_names = case restaurant.genre
               when '和食' then ['日替わり定食', '焼魚定食', '天ぷら定食', '刺身定食']
               when 'イタリアン' then ['ミートソースパスタ', 'カルボナーラ', 'マルゲリータピザ', 'ペペロンチーノ']
               when '中華' then ['麻婆豆腐定食', '回鍋肉定食', '酢豚定食', 'チャーハンセット']
               when '洋食' then ['ハンバーグプレート', 'オムライス', 'ビーフシチュー', 'グリルチキン']
               when '寿司' then ['にぎり寿司セット', 'ちらし寿司', '海鮮丼', '特上にぎり']
               when 'フレンチ' then ['本日の魚料理', '牛肉のロースト', 'キッシュランチ', 'コース料理']
               when '焼肉' then ['焼肉定食', 'カルビ定食', 'ロース定食', 'ミックス定食']
               when 'エスニック' then ['グリーンカレー', 'ガパオライス', 'パッタイ', 'トムヤムクン']
               when '定食' then ['日替わり定食', '唐揚げ定食', '生姜焼き定食', 'サバの味噌煮定食']
               else ['ランチセット', 'ディナーセット', '日替わりメニュー']
               end

  menu_names.sample(3).each do |menu_name|
    menu = Menu.create!(
      restaurant: restaurant,
      name: menu_name,
      description: "#{restaurant.name}の人気メニューです。",
      price_per_meal: [600, 700, 800, 900, 1000, 1200].sample,
      is_active: true
    )
    menus << menu
    puts "メニュー作成: #{restaurant.name} - #{menu.name}"
  end
end

# 備品
supplies = []
[
  { name: '割り箸', sku: 'SUP-001', category: '使い捨て備品', unit: '膳' },
  { name: '紙ナプキン', sku: 'SUP-002', category: '使い捨て備品', unit: '枚' },
  { name: '割り箸袋', sku: 'SUP-003', category: '使い捨て備品', unit: '枚' },
  { name: 'プラスチック容器（大）', sku: 'SUP-004', category: '使い捨て備品', unit: '個' },
  { name: 'プラスチック容器（小）', sku: 'SUP-005', category: '使い捨て備品', unit: '個' },
  { name: '保温バッグ', sku: 'SUP-006', category: '企業貸与備品', unit: '個' },
  { name: '保冷剤', sku: 'SUP-007', category: '企業貸与備品', unit: '個' },
  { name: '配送ボックス', sku: 'SUP-008', category: '企業貸与備品', unit: '個' },
  { name: 'ステンレストレー', sku: 'SUP-009', category: '飲食店貸与備品', unit: '個' },
  { name: '温度計', sku: 'SUP-010', category: '飲食店貸与備品', unit: '個' },
  { name: 'タオル', sku: 'SUP-011', category: '飲食店貸与備品', unit: '枚' },
  { name: '使い捨て手袋', sku: 'SUP-012', category: '使い捨て備品', unit: '枚' },
  { name: '配送伝票', sku: 'SUP-013', category: '使い捨て備品', unit: '枚' },
  { name: 'アルコール消毒液', sku: 'SUP-014', category: '使い捨て備品', unit: 'ml' },
  { name: '保温ジャー', sku: 'SUP-015', category: '飲食店貸与備品', unit: '個' }
].each do |supply_data|
  supply = Supply.create!(
    name: supply_data[:name],
    sku: supply_data[:sku],
    category: supply_data[:category],
    unit: supply_data[:unit],
    reorder_point: [50, 100, 200, 300].sample,
    is_active: true
  )
  supplies << supply
  puts "備品作成: #{supply.name}"
end

# 備品在庫
# 自社拠点の在庫
own_locations.each do |own_location|
  supplies.each do |supply|
    SupplyStock.create!(
      supply: supply,
      location: own_location,
      quantity: rand(100..500),
      physical_count: nil,
      last_updated_at: Time.current
    )
  end
  puts "#{own_location.name}の在庫作成完了"
end

# 企業在庫
companies.sample(3).each do |company|
  supplies.select { |s| s.category == '企業貸与備品' }.each do |supply|
    SupplyStock.create!(
      supply: supply,
      location: company,
      quantity: rand(5..30),
      last_updated_at: Time.current
    )
  end
  puts "#{company.name}の在庫作成完了"
end

# 飲食店在庫
restaurants.sample(5).each do |restaurant|
  supplies.select { |s| ['飲食店貸与備品', '使い捨て備品'].include?(s.category) }.sample(3).each do |supply|
    SupplyStock.create!(
      supply: supply,
      location: restaurant,
      quantity: rand(10..50),
      last_updated_at: Time.current
    )
  end
  puts "#{restaurant.name}の在庫作成完了"
end

# 備品移動履歴
10.times do
  from_company = companies.sample
  to_company = companies.sample

  movement_type = ['移動', '入荷', '消費'].sample

  # 移動種別に応じて拠点を設定
  from_loc = case movement_type
             when '入荷' then nil  # 入荷は移動元なし
             when '消費' then [from_company, restaurants.sample, nil].sample
             when '移動' then [from_company, restaurants.sample, nil].sample
             end

  to_loc = case movement_type
           when '消費' then nil  # 消費は移動先なし
           when '入荷' then [to_company, restaurants.sample, nil].sample
           when '移動' then [to_company, restaurants.sample, nil].sample
           end

  SupplyMovement.create!(
    supply: supplies.sample,
    movement_type: movement_type,
    quantity: rand(1..20),
    from_location: from_loc,
    to_location: to_loc,
    movement_date: Date.today - rand(30).days,
    notes: ['通常配送', '緊急補充', '定期補充', '返却品', '初回配送'].sample
  )
end
puts "備品移動履歴作成完了"

# 注文
orders = []
20.times do
  company = companies.sample
  restaurant = restaurants.sample
  menu = restaurant.menus.sample

  order = Order.create!(
    company: company,
    restaurant: restaurant,
    menu: menu,
    second_menu: restaurant.menus.where.not(id: menu.id).sample,
    delivery_company: delivery_companies.sample,
    order_type: ['定期', 'スポット', 'トライアル'].sample,
    scheduled_date: Date.today + rand(-7..7).days,
    default_meal_count: company.default_meal_count,
    confirmed_meal_count: nil,
    status: ['確認待ち', '確定', '準備中', '配送中', '完了'].sample,
    restaurant_status: ['未確認', '確認済み', '調理中', '完成'].sample,
    delivery_company_status: ['未配送', '配送準備', '配送中', '配送完了'].sample,
    delivery_group: rand(1..5),
    delivery_priority: rand(1..10)
  )
  orders << order
end
puts "注文作成完了: #{orders.count}件"

# 配送シート項目
orders.each do |order|
  # 飲食店から企業への配送
  DeliverySheetItem.create!(
    order: order,
    driver: drivers.sample,
    delivery_date: order.scheduled_date,
    sequence: 1,
    action_type: '引取',
    location_type: 'Restaurant',
    location_name: order.restaurant.name,
    address: '東京都渋谷区〇〇',
    phone: order.restaurant.contact_phone,
    scheduled_time: '10:00',
    meal_info: "#{order.menu.name} #{order.default_meal_count}食",
    supplies_info: '保温バッグ 2個',
    has_setup: false
  )

  DeliverySheetItem.create!(
    order: order,
    driver: drivers.sample,
    delivery_date: order.scheduled_date,
    sequence: 2,
    action_type: '配送',
    location_type: 'Company',
    location_name: order.company.name,
    address: '東京都千代田区〇〇',
    phone: order.company.contact_phone,
    scheduled_time: '12:00',
    meal_info: "#{order.menu.name} #{order.default_meal_count}食",
    supplies_info: '保温バッグ 2個',
    has_setup: order.company.has_setup,
    notes: order.company.has_setup ? nil : '初回配送につきセットアップ要'
  )
end
puts "配送シート項目作成完了"

puts "\n=========================================="
puts "seedデータ作成完了！"
puts "=========================================="
puts "AdminUser: #{AdminUser.count}件"
puts "Staff: #{Staff.count}件"
puts "OwnLocation: #{OwnLocation.count}件"
puts "Company: #{Company.count}件"
puts "Restaurant: #{Restaurant.count}件"
puts "DeliveryCompany: #{DeliveryCompany.count}件"
puts "Driver: #{Driver.count}件"
puts "Menu: #{Menu.count}件"
puts "Supply: #{Supply.count}件"
puts "SupplyStock: #{SupplyStock.count}件"
puts "SupplyMovement: #{SupplyMovement.count}件"
puts "Order: #{Order.count}件"
puts "DeliverySheetItem: #{DeliverySheetItem.count}件"
puts "=========================================="
puts "ログイン情報: admin@example.com / password"
puts "=========================================="

# frozen_string_literal: true

puts "seedデータ作成開始..."

# 既存データをクリア
AdminUser.destroy_all
OwnLocation.destroy_all
DeliveryCompany.destroy_all
Driver.destroy_all
Company.destroy_all
Restaurant.destroy_all
Menu.destroy_all
Supply.destroy_all
Order.destroy_all
OrderItem.destroy_all
RecurringOrder.destroy_all
SupplyStock.destroy_all
SupplyMovement.destroy_all
DeliverySheetItem.destroy_all

# =====================================================
# 管理者ユーザー
# =====================================================
admin = AdminUser.create!(
  email: 'admin@example.com',
  password: 'password',
  password_confirmation: 'password',
  name: '管理者'
)
puts "管理者ユーザー作成: #{admin.email}"

# =====================================================
# 自社拠点
# =====================================================
own_locations = []
[
  { name: '本社倉庫', address: '東京都港区虎ノ門1-1-1', location_type: '倉庫' },
  { name: '虎ノ門本社', address: '東京都港区虎ノ門2-2-2', location_type: 'オフィス' },
  { name: '第二倉庫', address: '東京都品川区大井3-3-3', location_type: '倉庫' },
  { name: '品川営業所', address: '東京都品川区北品川4-4-4', location_type: 'オフィス' }
].each do |loc|
  location = OwnLocation.create!(
    name: loc[:name],
    address: loc[:address],
    location_type: loc[:location_type]
  )
  own_locations << location
  puts "自社拠点作成: #{location.name}"
end

# =====================================================
# 配送会社
# =====================================================
delivery_companies = []
[
  { name: '東京配送サービス', phone: '03-1111-2222' },
  { name: '関東運輸', phone: '03-3333-4444' },
  { name: '首都圏デリバリー', phone: '03-5555-6666' }
].each do |dc|
  company = DeliveryCompany.create!(
    name: dc[:name],
    phone: dc[:phone]
  )
  delivery_companies << company
  puts "配送会社作成: #{company.name}"
end

# =====================================================
# ドライバー
# =====================================================
drivers = []
delivery_companies.each do |dc|
  3.times do |i|
    driver = Driver.create!(
      name: "#{dc.name.split('').first(2).join}ドライバー#{('A'.ord + i).chr}",
      delivery_company: dc,
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}"
    )
    drivers << driver
    puts "ドライバー作成: #{driver.name}"
  end
end

# =====================================================
# 導入企業
# =====================================================
companies = []
[
  { name: 'テック株式会社', formal_name: '株式会社テック', contract_status: 'active' },
  { name: 'サンプル商事', formal_name: 'サンプル商事株式会社', contract_status: 'active' },
  { name: 'ABC工業', formal_name: 'ABC工業株式会社', contract_status: 'trial' },
  { name: 'デジタルソリューションズ', formal_name: '株式会社デジタルソリューションズ', contract_status: 'active' },
  { name: 'グリーン物産', formal_name: 'グリーン物産株式会社', contract_status: 'prospect' }
].each do |comp|
  company = Company.create!(
    name: comp[:name],
    formal_name: comp[:formal_name],
    contract_status: comp[:contract_status],
    contact_person: '担当者',
    contact_phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    contact_email: "contact@#{comp[:name].gsub(/[^a-z0-9]/i, '').downcase}.co.jp",
    first_delivery_date: Date.today - rand(30..180).days
  )
  companies << company
  puts "導入企業作成: #{company.name}"
end

# =====================================================
# 飲食店
# =====================================================
restaurants = []
[
  { name: '和食処 さくら', genre: '和食', contract_status: 'active', max_capacity: 100 },
  { name: 'イタリアンキッチン ベラ', genre: 'イタリアン', contract_status: 'active', max_capacity: 80 },
  { name: '中華料理 龍門', genre: '中華', contract_status: 'active', max_capacity: 120 },
  { name: 'カフェ&ダイニング オリーブ', genre: 'カフェ', contract_status: 'active', max_capacity: 60 },
  { name: '寿司割烹 海', genre: '和食', contract_status: 'active', max_capacity: 50 },
  { name: 'フレンチビストロ ル・ソレイユ', genre: 'フレンチ', contract_status: 'active', max_capacity: 40 },
  { name: '焼肉ダイニング 牛角', genre: '焼肉', contract_status: 'active', max_capacity: 90 },
  { name: 'タイ料理 バンコク', genre: 'タイ料理', contract_status: 'active', max_capacity: 70 },
  { name: 'パスタ工房 ポモドーロ', genre: 'イタリアン', contract_status: 'active', max_capacity: 85 },
  { name: '定食屋 まごころ', genre: '定食', contract_status: 'active', max_capacity: 110 }
].each do |rest|
  restaurant = Restaurant.create!(
    name: rest[:name],
    genre: rest[:genre],
    contract_status: rest[:contract_status],
    max_capacity: rest[:max_capacity],
    phone: "03-#{rand(1000..9999)}-#{rand(1000..9999)}",
    contact_person: '店長'
  )
  restaurants << restaurant
  puts "飲食店作成: #{restaurant.name}"
end

# =====================================================
# メニュー（各飲食店3つずつ）
# =====================================================
menus = []
menu_names = {
  '和食処 さくら' => ['刺身定食', '天ぷら定食', '日替わり定食'],
  'イタリアンキッチン ベラ' => ['カルボナーラ', 'ミートソースパスタ', 'マルゲリータピザ'],
  '中華料理 龍門' => ['回鍋肉定食', '麻婆豆腐定食', 'チャーハンセット'],
  'カフェ&ダイニング オリーブ' => ['オムライス', 'ハンバーグプレート', 'ビーフシチュー'],
  '寿司割烹 海' => ['ちらし寿司', 'にぎり寿司セット', '海鮮丼'],
  'フレンチビストロ ル・ソレイユ' => ['キッシュランチ', 'コース料理', '本日の魚料理'],
  '焼肉ダイニング 牛角' => ['焼肉定食', 'カルビ定食', 'ミックス定食'],
  'タイ料理 バンコク' => ['ガパオライス', 'パッタイ', 'トムヤムクン'],
  'パスタ工房 ポモドーロ' => ['ペペロンチーノ', 'マルゲリータピザ', 'ミートソースパスタ'],
  '定食屋 まごころ' => ['唐揚げ定食', '日替わり定食', '生姜焼き定食']
}

restaurants.each do |restaurant|
  menu_list = menu_names[restaurant.name] || ['メニューA', 'メニューB', 'メニューC']
  menu_list.each do |menu_name|
    menu = Menu.create!(
      restaurant: restaurant,
      name: menu_name,
      price_per_meal: rand(800..1500),
      tax_rate: [8, 10].sample,
      is_active: true
    )
    menus << menu
    puts "メニュー作成: #{restaurant.name} - #{menu.name}"
  end
end

# =====================================================
# 定期案件
# =====================================================
recurring_orders = []
# 契約中とトライアルの企業に定期案件を作成
companies.select { |c| ['active', 'trial'].include?(c.contract_status) }.each do |company|
  # ランダムに2〜4曜日で定期案件を作成
  rand(2..4).times do
    day = rand(0..6)
    # 既に同じ曜日の定期案件がある場合はスキップ
    next if company.recurring_orders.exists?(day_of_week: day)

    ro = RecurringOrder.create!(
      company: company,
      day_of_week: day,
      meal_count: rand(10..50),
      delivery_time: Time.zone.parse("#{['10:00', '11:00', '12:00'].sample}"),
      is_active: true,
      status: 'active',
      notes: ['通常配送', '特急配送', nil].sample
    )
    recurring_orders << ro
    puts "定期案件作成: #{company.name} - #{%w[日 月 火 水 木 金 土][day]}曜日"
  end
end

# =====================================================
# 備品マスター
# =====================================================
supplies = []
[
  { name: '割り箸', sku: 'SUP-001', category: '使い捨て備品', unit: '膳' },
  { name: '紙ナプキン', sku: 'SUP-002', category: '使い捨て備品', unit: '枚' },
  { name: '割り箸袋', sku: 'SUP-003', category: '使い捨て備品', unit: '枚' },
  { name: 'プラスチック容器（大）', sku: 'SUP-004', category: '使い捨て備品', unit: '個' },
  { name: 'プラスチック容器（小）', sku: 'SUP-005', category: '使い捨て備品', unit: '個' },
  { name: '保温バッグ', sku: 'SUP-006', category: '企業貸与備品', unit: '個' },
  { name: '保冷剤', sku: 'SUP-007', category: '使い捨て備品', unit: '個' },
  { name: '配送ボックス', sku: 'SUP-008', category: '企業貸与備品', unit: '個' },
  { name: 'ステンレストレー', sku: 'SUP-009', category: '飲食店貸与備品', unit: '個' },
  { name: '温度計', sku: 'SUP-010', category: '企業貸与備品', unit: '個' },
  { name: 'タオル', sku: 'SUP-011', category: '企業貸与備品', unit: '枚' },
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

# =====================================================
# 備品在庫
# =====================================================
# 自社拠点の在庫
own_locations.each do |own_location|
  supplies.sample(rand(5..10)).each do |supply|
    SupplyStock.create!(
      supply: supply,
      location: own_location,
      quantity: rand(100..500)
    )
  end
  puts "#{own_location.name}の在庫作成完了"
end

# 一部の企業と飲食店の在庫
(companies.sample(3) + restaurants.sample(5)).each do |location|
  supplies.sample(rand(3..8)).each do |supply|
    SupplyStock.create!(
      supply: supply,
      location: location,
      quantity: rand(10..100)
    )
  end
  puts "#{location.name}の在庫作成完了"
end

# =====================================================
# 備品移動履歴（status: '予定'で在庫更新を無効化）
# =====================================================
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
    status: '予定',
    notes: ['通常配送', '緊急補充', '定期補充', '返却品', '初回配送'].sample
  )
end
puts "備品移動履歴作成完了"

# =====================================================
# 注文
# =====================================================
orders = []
20.times do
  company = companies.sample
  restaurant = restaurants.sample
  menus_for_order = restaurant.menus.sample(rand(1..2))

  order = Order.create!(
    company: company,
    restaurant: restaurant,
    delivery_company: delivery_companies.sample,
    order_type: ['定期', 'スポット', 'トライアル'].sample,
    scheduled_date: Date.today + rand(-7..7).days,
    status: '未完了',
    restaurant_status: ['未確認', '確認済み', '調理中', '完成'].sample,
    delivery_company_status: ['未配送', '配送準備', '配送中', '配送完了'].sample,
    total_meal_count: 0,  # calculate_totalsで自動計算
    subtotal: 0,
    tax: 0,
    tax_8_percent: 0,
    tax_10_percent: 0,
    delivery_fee: rand(0..500),
    delivery_fee_tax: 0,
    discount_amount: 0,
    total_price: 0
  )

  # 注文明細を作成
  menus_for_order.each do |menu|
    quantity = rand(5..25)
    unit_price = menu.price_per_meal
    OrderItem.create!(
      order: order,
      menu: menu,
      quantity: quantity,
      unit_price: unit_price,
      subtotal: quantity * unit_price,
      tax_rate: menu.tax_rate
    )
  end

  # 合計を再計算して保存
  order.save!

  orders << order
end
puts "注文作成完了: #{orders.count}件"

# =====================================================
# 配送シート項目
# =====================================================
orders.each_with_index do |order, idx|
  # 飲食店から企業への配送
  DeliverySheetItem.create!(
    order: order,
    delivery_date: order.scheduled_date,
    sequence: idx * 2 + 1,
    action_type: '配送',
    delivery_type: order.order_type,
    scheduled_time: order.scheduled_date.to_time + 11.hours,
    location_type: 'Company',
    location_name: order.company.name,
    address: order.company.delivery_address,
    phone: order.company.contact_phone
  )

  # 企業から飲食店への回収
  DeliverySheetItem.create!(
    order: order,
    delivery_date: order.scheduled_date,
    sequence: idx * 2 + 2,
    action_type: '回収',
    delivery_type: order.order_type,
    scheduled_time: order.scheduled_date.to_time + 14.hours,
    location_type: 'Restaurant',
    location_name: order.restaurant.name,
    address: order.restaurant.pickup_address,
    phone: order.restaurant.phone
  )
end
puts "配送シート項目作成完了"

puts "\n=========================================="
puts "seedデータ作成完了！"
puts "=========================================="
puts "AdminUser: #{AdminUser.count}件"
puts "OwnLocation: #{OwnLocation.count}件"
puts "Company: #{Company.count}件"
puts "Restaurant: #{Restaurant.count}件"
puts "DeliveryCompany: #{DeliveryCompany.count}件"
puts "Driver: #{Driver.count}件"
puts "Menu: #{Menu.count}件"
puts "RecurringOrder: #{RecurringOrder.count}件"
puts "Supply: #{Supply.count}件"
puts "SupplyStock: #{SupplyStock.count}件"
puts "SupplyMovement: #{SupplyMovement.count}件"
puts "Order: #{Order.count}件"
puts "OrderItem: #{OrderItem.count}件"
puts "DeliverySheetItem: #{DeliverySheetItem.count}件"
puts "=========================================="
puts "ログイン情報: admin@example.com / password"
puts "=========================================="

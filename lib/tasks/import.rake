namespace :import do
  desc "全てのマスタデータをインポート"
  task all: :environment do
    Rake::Task['import:companies'].invoke
    Rake::Task['import:restaurants'].invoke
    Rake::Task['import:menus'].invoke
    Rake::Task['import:delivery_companies'].invoke
    puts "全てのデータのインポートが完了しました"
  end

  desc "導入企業マスタをインポート"
  task companies: :environment do
    require 'roo'

    file_path = ENV['COMPANIES_FILE'] || '/path/to/companies.xlsx'

    unless File.exist?(file_path)
      puts "エラー: ファイルが見つかりません: #{file_path}"
      puts "COMPANIES_FILE 環境変数でファイルパスを指定してください"
      next
    end

    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    # ヘッダー行をスキップして2行目から処理
    (2..sheet.last_row).each do |i|
      Company.find_or_create_by!(
        name: sheet.cell(i, 1),
        formal_name: sheet.cell(i, 2) || sheet.cell(i, 1),
        contract_status: sheet.cell(i, 3) || '本導入',
        default_meal_count: sheet.cell(i, 4) || 40
      )
    end

    puts "導入企業マスタのインポートが完了しました（#{Company.count}件）"
  end

  desc "飲食店マスタをインポート"
  task restaurants: :environment do
    require 'roo'

    file_path = ENV['RESTAURANTS_FILE'] || '/path/to/restaurants.xlsx'

    unless File.exist?(file_path)
      puts "エラー: ファイルが見つかりません: #{file_path}"
      puts "RESTAURANTS_FILE 環境変数でファイルパスを指定してください"
      next
    end

    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    (2..sheet.last_row).each do |i|
      Restaurant.find_or_create_by!(
        name: sheet.cell(i, 1),
        contract_status: sheet.cell(i, 2) || '契約済み',
        genre: sheet.cell(i, 3),
        max_capacity: sheet.cell(i, 4) || 100,
        pickup_time_with_main: sheet.cell(i, 5),
        pickup_time_trial_only: sheet.cell(i, 6)
      )
    end

    puts "飲食店マスタのインポートが完了しました（#{Restaurant.count}件）"
  end

  desc "メニューマスタをインポート"
  task menus: :environment do
    require 'roo'

    file_path = ENV['MENUS_FILE'] || '/path/to/menus.xlsx'

    unless File.exist?(file_path)
      puts "エラー: ファイルが見つかりません: #{file_path}"
      puts "MENUS_FILE 環境変数でファイルパスを指定してください"
      next
    end

    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    (2..sheet.last_row).each do |i|
      restaurant_name = sheet.cell(i, 1)
      restaurant = Restaurant.find_by(name: restaurant_name)

      unless restaurant
        puts "警告: 飲食店が見つかりません: #{restaurant_name}"
        next
      end

      Menu.find_or_create_by!(
        restaurant: restaurant,
        name: sheet.cell(i, 2),
        price_per_meal: sheet.cell(i, 3) || 649
      )
    end

    puts "メニューマスタのインポートが完了しました（#{Menu.count}件）"
  end

  desc "配送会社マスタをインポート"
  task delivery_companies: :environment do
    # デフォルトの配送会社を作成
    DeliveryCompany.find_or_create_by!(name: 'SAZAKI')
    DeliveryCompany.find_or_create_by!(name: 'MIRAIS')

    puts "配送会社マスタのインポートが完了しました（#{DeliveryCompany.count}件）"
  end

  desc "サンプルデータを作成"
  task sample: :environment do
    # スタッフ
    staff = Staff.find_or_create_by!(name: '山田太郎', email: 'yamada@example.com', role: '管理者')

    # 導入企業
    company1 = Company.find_or_create_by!(
      name: 'TVer',
      formal_name: '株式会社TVer',
      contract_status: '本導入',
      default_meal_count: 100
    )

    company2 = Company.find_or_create_by!(
      name: 'AOI Pro',
      formal_name: '株式会社AOI Pro',
      contract_status: '本導入',
      default_meal_count: 40
    )

    # 飲食店
    restaurant1 = Restaurant.find_or_create_by!(
      name: 'カリカル',
      contract_status: '契約済み',
      genre: 'カレー',
      max_capacity: 150,
      pickup_time_with_main: '10:00',
      pickup_time_trial_only: '10:30'
    )

    restaurant2 = Restaurant.find_or_create_by!(
      name: 'ロダン',
      contract_status: '契約済み',
      genre: 'カレー',
      max_capacity: 100,
      pickup_time_with_main: '10:00',
      pickup_time_trial_only: '10:30'
    )

    # メニュー
    menu1 = Menu.find_or_create_by!(
      restaurant: restaurant1,
      name: 'チキンカレー',
      price_per_meal: 649
    )

    menu2 = Menu.find_or_create_by!(
      restaurant: restaurant2,
      name: 'ビーフカレー',
      price_per_meal: 649
    )

    # 配送会社
    sazaki = DeliveryCompany.find_or_create_by!(name: 'SAZAKI')
    mirais = DeliveryCompany.find_or_create_by!(name: 'MIRAIS')

    # ドライバー
    Driver.find_or_create_by!(
      delivery_company: sazaki,
      name: '坪井健司',
      phone: '090-3530-9251'
    )

    puts "サンプルデータの作成が完了しました"
  end
end

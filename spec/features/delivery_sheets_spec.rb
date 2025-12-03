require 'rails_helper'

RSpec.feature "DeliverySheets", type: :feature do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') }
  let(:company) { Company.create!(name: 'テスト企業', formal_name: 'テスト企業株式会社', contract_status: 'active', color: '#2196f3') }
  let(:restaurant) do
    Restaurant.create!(
      name: 'テスト飲食店',
      contract_status: 'active',
      max_capacity: 100,
      capacity_per_day: 50
    )
  end
  let(:menu) { Menu.create!(name: 'テストメニュー', restaurant: restaurant) }
  let(:delivery_company) { DeliveryCompany.create!(name: 'テスト配送会社') }

  before do
    sign_in admin_user
  end

  scenario "配送シート一覧が表示される" do
    order = Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed',
      collection_time: Time.zone.parse('12:00'),
      warehouse_pickup_time: Time.zone.parse('10:00'),
      is_trial: true,
      return_location: '倉庫',
      equipment_notes: 'テストメモ'
    )

    visit delivery_sheets_admin_orders_path

    # 案件情報が表示されることを確認
    expect(page).to have_content(company.name)
    expect(page).to have_content(restaurant.name)
    expect(page).to have_content(menu.name)
    expect(page).to have_content('20')
    expect(page).to have_content('試食会')
  end

  scenario "期間を指定してフィルタリングする" do
    # 今日の案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed'
    )

    # 来週の案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today + 7.days,
      default_meal_count: 15,
      status: 'confirmed'
    )

    visit delivery_sheets_admin_orders_path

    # フィルターを開く
    click_button 'フィルター'

    # 今日から3日後までの期間を指定
    fill_in 'start_date', with: Date.today.to_s
    fill_in 'end_date', with: (Date.today + 3.days).to_s
    click_button 'フィルター適用'

    # 今日の案件のみ表示されることを確認
    expect(page).to have_content('合計 1 件の配送案件')
  end

  scenario "PDF出力ボタンが機能する" do
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed',
      collection_time: Time.zone.parse('12:00'),
      warehouse_pickup_time: Time.zone.parse('10:00')
    )

    visit delivery_sheets_admin_orders_path

    # PDF出力ボタンが存在することを確認
    expect(page).to have_link('PDF出力')
  end

  scenario "キャンセルされた案件は表示されない" do
    # 通常の案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed'
    )

    # キャンセルされた案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 15,
      status: 'cancelled'
    )

    visit delivery_sheets_admin_orders_path

    # キャンセルされた案件は含まれない
    expect(page).to have_content('合計 1 件の配送案件')
  end

  scenario "日付ごとにグループ化されて表示される" do
    # 今日の案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed'
    )

    # 明日の案件
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today + 1.day,
      default_meal_count: 15,
      status: 'confirmed'
    )

    visit delivery_sheets_admin_orders_path

    # 日付ヘッダーが表示されることを確認
    expect(page).to have_content(Date.today.strftime('%Y年%m月%d日'))
    expect(page).to have_content((Date.today + 1.day).strftime('%Y年%m月%d日'))
  end

  scenario "配送会社でフィルタリングする" do
    Order.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      delivery_company: delivery_company,
      order_type: 'trial',
      scheduled_date: Date.today,
      default_meal_count: 20,
      status: 'confirmed'
    )

    visit delivery_sheets_admin_orders_path

    # フィルターを開く
    click_button 'フィルター'

    # 配送会社でフィルタリング
    select delivery_company.name, from: 'delivery_company_id'
    click_button 'フィルター適用'

    expect(page).to have_content('合計 1 件の配送案件')
  end
end

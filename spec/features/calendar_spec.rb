require 'rails_helper'

RSpec.feature "Calendar", type: :feature do
  let(:admin_user) { AdminUser.create!(name: 'テスト管理者', email: 'admin@example.com', password: 'password', password_confirmation: 'password') }
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

  before do
    sign_in admin_user
  end

  scenario "カレンダーに案件が表示される" do
    # 今月の案件を作成
    order = create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 20,
      status: 'confirmed',
      collection_time: Time.zone.parse('12:00')
    )

    visit calendar_admin_orders_path

    # 案件が表示されることを確認
    expect(page).to have_content(company.name)
    expect(page).to have_content(restaurant.name)
  end

  scenario "月間表示と週間表示を切り替える" do
    visit calendar_admin_orders_path

    # 初期状態は月間表示
    expect(page).to have_content('月間表示')

    # 週間表示に切り替え
    click_link '週間表示に切替'
    expect(page).to have_content('週間表示')

    # 月間表示に戻す
    click_link '月間表示に切替'
    expect(page).to have_content('月間表示')
  end

  scenario "企業でフィルタリングする" do
    company2 = Company.create!(name: 'テスト企業2', formal_name: 'テスト企業2株式会社', contract_status: 'active', color: '#ff5722')

    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 20,
      status: 'confirmed'
    )

    create_order_with_items(
      company: company2,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 15,
      status: 'confirmed'
    )

    visit calendar_admin_orders_path

    # フィルターを開く
    click_button 'フィルター'

    # 企業1でフィルタリング
    select company.name, from: 'company_id'
    click_button 'フィルター適用'

    expect(page).to have_content(company.name)
    expect(page).not_to have_content(company2.name)
  end

  scenario "メニュー重複警告が表示される" do
    # 同じ週に同じメニューの案件を2つ作成
    monday = Date.today.beginning_of_week(:monday)

    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: monday,
      meal_count: 20,
      status: 'confirmed'
    )

    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: monday + 2.days,
      meal_count: 20,
      status: 'confirmed'
    )

    visit calendar_admin_orders_path(view: 'week', start_date: monday)

    # 警告アイコンが表示されることを確認
    expect(page).to have_css('.fa-exclamation-triangle.text-warning')
  end

  scenario "カレンダーから配送シート画面に遷移する" do
    visit calendar_admin_orders_path

    click_link '配送シート'

    expect(current_path).to eq(delivery_sheets_admin_orders_path)
  end
end

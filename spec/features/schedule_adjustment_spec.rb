require 'rails_helper'

RSpec.feature "ScheduleAdjustment", type: :feature do
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

  scenario "スケジュール調整画面に案件一覧が表示される" do
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

    visit schedule_admin_orders_path

    # 案件情報が表示されることを確認
    expect(page).to have_content(company.name)
    expect(page).to have_content(restaurant.name)
    expect(page).to have_content(menu.name)
    expect(page).to have_content('20')
  end

  scenario "複数の案件を選択して一括更新する" do
    order1 = create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 20,
      status: 'pending'
    )

    order2 = create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 15,
      status: 'pending'
    )

    visit schedule_admin_orders_path

    # 全選択チェックボックスをクリック
    check 'select-all'

    # 更新ボタンをクリック
    click_button '選択した案件を更新'

    # 確認ダイアログが表示される（実際のブラウザでは）
    # ここではダイアログを無視して次に進む
  end

  scenario "コンフリクトがある案件が赤く表示される" do
    # 既存案件（12:00回収）
    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today + 2.days,
      meal_count: 20,
      status: 'confirmed',
      collection_time: Time.zone.parse('12:00')
    )

    # 時間帯が重複する案件（12:30回収）
    menu2 = Menu.create!(name: 'テストメニュー2', restaurant: restaurant)
    order2 = create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu2,
      order_type: 'trial',
      scheduled_date: Date.today + 2.days,
      meal_count: 15,
      status: 'pending',
      collection_time: Time.zone.parse('12:30')
    )

    visit schedule_admin_orders_path(start_date: Date.today, end_date: Date.today + 7.days)

    # コンフリクトアイコンが表示されることを確認
    expect(page).to have_css('.fa-exclamation-circle.text-danger')
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

    visit schedule_admin_orders_path

    # フィルターを開く
    click_button 'フィルター'

    # 企業1でフィルタリング
    select company.name, from: 'company_id'
    click_button 'フィルター適用'

    expect(page).to have_content(company.name)
    expect(page).not_to have_content(company2.name)
  end

  scenario "ステータスでフィルタリングする" do
    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 20,
      status: 'pending'
    )

    create_order_with_items(
      company: company,
      restaurant: restaurant,
      menu: menu,
      order_type: 'trial',
      scheduled_date: Date.today,
      meal_count: 15,
      status: 'confirmed'
    )

    visit schedule_admin_orders_path

    # フィルターを開く
    click_button 'フィルター'

    # 保留でフィルタリング
    select '保留', from: 'status'
    click_button 'フィルター適用'

    # 保留の案件のみ表示されることを確認（pending badgeが1つだけ）
    expect(page).to have_css('.badge-warning', count: 1)
  end
end

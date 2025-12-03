require 'rails_helper'

RSpec.feature "RecurringOrders", type: :feature do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') }
  let(:company) { Company.create!(name: 'テスト企業', invoice_recipient: 'テスト企業') }
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

  scenario "定期スケジュールを登録する" do
    visit admin_recurring_orders_path

    click_link '新規作成'

    # フォーム入力
    select company.name, from: 'recurring_order[company_id]'
    select restaurant.name, from: 'recurring_order[restaurant_id]'
    select menu.name, from: 'recurring_order[menu_id]'
    select 'monday', from: 'recurring_order[day_of_week]'
    fill_in 'recurring_order[default_meal_count]', with: '20'
    fill_in 'recurring_order[start_date]', with: Date.today.to_s
    fill_in 'recurring_order[end_date]', with: (Date.today + 3.months).to_s

    click_button '作成する'

    expect(page).to have_content('定期注文を作成しました')
    expect(page).to have_content(company.name)
    expect(page).to have_content(restaurant.name)
  end

  scenario "定期スケジュールから案件を自動生成する" do
    # 定期スケジュール作成
    recurring_order = RecurringOrder.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      day_of_week: 'monday',
      frequency: 'weekly',
      default_meal_count: 20,
      start_date: Date.today,
      end_date: Date.today + 3.months
    )

    visit admin_recurring_orders_path

    # 一括生成ボタンをクリック
    click_link '案件を自動生成'

    expect(page).to have_content('案件を生成しました')

    # 生成された案件を確認
    visit admin_orders_path
    expect(page).to have_content(company.name)
    expect(page).to have_content(restaurant.name)
  end

  scenario "定期スケジュールを編集する" do
    recurring_order = RecurringOrder.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      day_of_week: 'monday',
      frequency: 'weekly',
      default_meal_count: 20,
      start_date: Date.today,
      end_date: Date.today + 3.months
    )

    visit admin_recurring_orders_path

    # 編集リンクをクリック（最初の行）
    first('.table tbody tr').click_link '編集'

    # 食数を変更
    fill_in 'recurring_order[default_meal_count]', with: '25'
    click_button '更新する'

    expect(page).to have_content('定期注文を更新しました')
    expect(recurring_order.reload.default_meal_count).to eq(25)
  end

  scenario "定期スケジュールを削除する" do
    recurring_order = RecurringOrder.create!(
      company: company,
      restaurant: restaurant,
      menu: menu,
      day_of_week: 'monday',
      frequency: 'weekly',
      default_meal_count: 20,
      start_date: Date.today,
      end_date: Date.today + 3.months
    )

    visit admin_recurring_orders_path

    # 削除ボタンをクリック
    first('.table tbody tr').click_link '削除'

    expect(page).to have_content('定期注文を削除しました')
    expect(RecurringOrder.exists?(recurring_order.id)).to be false
  end
end

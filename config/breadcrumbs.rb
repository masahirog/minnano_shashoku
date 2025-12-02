# config/breadcrumbs.rb
crumb :root do
  link "TOP", admin_root_path
end

# 管理者
crumb :admin_admin_users do
  link "管理者", admin_admin_users_path
  parent :root
end

crumb :admin_admin_user do |admin_user|
  link "ID:#{admin_user.id} #{admin_user.email}", admin_admin_user_path(admin_user)
  parent :admin_admin_users
end

# 自社拠点
crumb :admin_own_locations do
  link "自社拠点", admin_own_locations_path
  parent :root
end

crumb :admin_own_location do |own_location|
  link "ID:#{own_location.id} #{own_location.name}", admin_own_location_path(own_location)
  parent :admin_own_locations
end

# スタッフ
crumb :admin_staffs do
  link "スタッフ", admin_staffs_path
  parent :root
end

crumb :admin_staff do |staff|
  link "ID:#{staff.id} #{staff.name}", admin_staff_path(staff)
  parent :admin_staffs
end

# 導入企業
crumb :admin_companies do
  link "導入企業", admin_companies_path
  parent :root
end

crumb :admin_company do |company|
  link "ID:#{company.id} #{company.name}", admin_company_path(company)
  parent :admin_companies
end

# 飲食店
crumb :admin_restaurants do
  link "飲食店", admin_restaurants_path
  parent :root
end

crumb :admin_restaurant do |restaurant|
  link "ID:#{restaurant.id} #{restaurant.name}", admin_restaurant_path(restaurant)
  parent :admin_restaurants
end

# 配送会社
crumb :admin_delivery_companies do
  link "配送会社", admin_delivery_companies_path
  parent :root
end

crumb :admin_delivery_company do |delivery_company|
  link "ID:#{delivery_company.id} #{delivery_company.name}", admin_delivery_company_path(delivery_company)
  parent :admin_delivery_companies
end

# ドライバー
crumb :admin_drivers do
  link "ドライバー", admin_drivers_path
  parent :root
end

crumb :admin_driver do |driver|
  link "ID:#{driver.id} #{driver.name}", admin_driver_path(driver)
  parent :admin_drivers
end

# メニュー
crumb :admin_menus do
  link "メニュー", admin_menus_path
  parent :root
end

crumb :admin_menu do |menu|
  link "ID:#{menu.id} #{menu.name}", admin_menu_path(menu)
  parent :admin_menus
end

# 案件
crumb :admin_orders do
  link "案件", admin_orders_path
  parent :root
end

crumb :admin_order do |order|
  link "ID:#{order.id} #{order.company&.name}", admin_order_path(order)
  parent :admin_orders
end

# 配送シート明細
crumb :admin_delivery_sheet_items do
  link "配送シート明細", admin_delivery_sheet_items_path
  parent :root
end

crumb :admin_delivery_sheet_item do |delivery_sheet_item|
  link "ID:#{delivery_sheet_item.id}", admin_delivery_sheet_item_path(delivery_sheet_item)
  parent :admin_delivery_sheet_items
end

# 備品
crumb :admin_supplies do
  link "備品", admin_supplies_path
  parent :root
end

crumb :admin_supply do |supply|
  link "ID:#{supply.id} #{supply.name}", admin_supply_path(supply)
  parent :admin_supplies
end

crumb :admin_supplies_by_location do
  link "拠点別在庫一覧", by_location_admin_supplies_path
  parent :admin_supplies
end

crumb :admin_supplies_by_location_with_supply do |supply|
  link "#{supply.name} の拠点別在庫", by_location_admin_supplies_path(supply_id: supply.id)
  parent :admin_supplies
end

# 在庫
crumb :admin_supply_stocks do
  link "在庫", admin_supply_stocks_path
  parent :root
end

crumb :admin_supply_stock do |supply_stock|
  link "ID:#{supply_stock.id}", admin_supply_stock_path(supply_stock)
  parent :admin_supply_stocks
end

crumb :admin_supply_stocks_by_location do
  link "拠点別在庫一覧", by_location_admin_supply_stocks_path
  parent :admin_supply_stocks
end

crumb :admin_supply_stocks_by_location_with_supply do |supply|
  link "#{supply.name} の拠点別在庫", by_location_admin_supply_stocks_path(supply_id: supply.id)
  parent :admin_supply_stocks
end

# 備品移動登録
crumb :admin_supply_movements do
  link "備品移動登録", admin_supply_movements_path
  parent :root
end

crumb :admin_supply_movement do |supply_movement|
  link "ID:#{supply_movement.id}", admin_supply_movement_path(supply_movement)
  parent :admin_supply_movements
end

# 一括備品移動登録
crumb :admin_bulk_supply_movements_new do
  link "一括備品移動登録", new_admin_bulk_supply_movement_path
  parent :admin_supply_movements
end

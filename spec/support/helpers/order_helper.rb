module OrderHelper
  # Order + OrderItems を作成するヘルパーメソッド
  #
  # @param company [Company] 企業（必須）
  # @param restaurant [Restaurant] 飲食店（オプション）
  # @param menu [Menu] メニュー（オプション、指定するとOrderItemを自動作成）
  # @param attributes [Hash] その他のOrder属性
  # @option attributes [Integer] :meal_count メニューの食数（デフォルト: 20）
  # @option attributes [Decimal] :unit_price メニューの単価（デフォルト: menu.price || 1000）
  # @return [Order]
  def create_order_with_items(company:, restaurant: nil, menu: nil, **attributes)
    # デフォルト値
    meal_count = attributes.delete(:meal_count) || attributes.delete(:default_meal_count) || 20
    unit_price = attributes.delete(:unit_price)

    # Order作成
    order = Order.create!(
      company: company,
      restaurant: restaurant,
      order_type: attributes[:order_type] || 'trial',
      scheduled_date: attributes[:scheduled_date] || Date.today,
      status: attributes[:status] || 'confirmed',
      collection_time: attributes[:collection_time],
      warehouse_pickup_time: attributes[:warehouse_pickup_time],
      return_location: attributes[:return_location],
      equipment_notes: attributes[:equipment_notes],
      delivery_company_id: attributes[:delivery_company_id],
      recurring_order_id: attributes[:recurring_order_id],
      is_trial: attributes[:is_trial] || false,
      delivery_fee: attributes[:delivery_fee] || 0,
      memo: attributes[:memo]
    )

    # MenuがあればOrderItemを作成
    if menu
      unit_price ||= menu.try(:price) || 1000

      OrderItem.create!(
        order: order,
        menu: menu,
        quantity: meal_count,
        unit_price: unit_price
      )

      # 合計を再計算
      order.reload
    end

    order
  end

  # 複数メニューのOrderを作成
  #
  # @param company [Company] 企業（必須）
  # @param restaurant [Restaurant] 飲食店（オプション）
  # @param menus [Array<Hash>] メニュー配列 [{menu: menu1, quantity: 10, unit_price: 1000}, ...]
  # @param attributes [Hash] その他のOrder属性
  # @return [Order]
  def create_order_with_multiple_menus(company:, restaurant: nil, menus: [], **attributes)
    # Order作成
    order = Order.create!(
      company: company,
      restaurant: restaurant,
      order_type: attributes[:order_type] || 'trial',
      scheduled_date: attributes[:scheduled_date] || Date.today,
      status: attributes[:status] || 'confirmed',
      collection_time: attributes[:collection_time],
      warehouse_pickup_time: attributes[:warehouse_pickup_time],
      return_location: attributes[:return_location],
      equipment_notes: attributes[:equipment_notes],
      delivery_company_id: attributes[:delivery_company_id],
      recurring_order_id: attributes[:recurring_order_id],
      is_trial: attributes[:is_trial] || false,
      delivery_fee: attributes[:delivery_fee] || 0,
      memo: attributes[:memo]
    )

    # 各メニューのOrderItemを作成
    menus.each do |menu_data|
      menu = menu_data[:menu]
      quantity = menu_data[:quantity] || menu_data[:meal_count] || 20
      unit_price = menu_data[:unit_price] || menu.try(:price) || 1000

      OrderItem.create!(
        order: order,
        menu: menu,
        quantity: quantity,
        unit_price: unit_price
      )
    end

    # 合計を再計算
    order.reload if menus.any?

    order
  end
end

RSpec.configure do |config|
  config.include OrderHelper
end

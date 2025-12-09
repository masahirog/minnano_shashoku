require "administrate/base_dashboard"

class OrderDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    company: Field::BelongsTo,
    restaurant: Field::BelongsTo,
    delivery_company: Field::BelongsTo,
    recurring_order: Field::BelongsTo,

    # 関連
    order_items: NestedHasManyField,
    menus: Field::HasMany,
    delivery_sheet_items: Field::HasMany,
    invoice_items: Field::HasMany,
    delivery_plan_items: DeliveryPlanItemsSummaryField,

    # 基本情報
    scheduled_date: Field::Date,
    order_type: Field::Select.with_options(
      collection: ::Order::ORDER_TYPES
    ),
    status: Field::Select.with_options(
      collection: ::Order::STATUSES
    ),

    # ステータス
    restaurant_status: Field::Select.with_options(
      collection: ::Order::RESTAURANT_STATUSES
    ),
    delivery_company_status: Field::Select.with_options(
      collection: ::Order::DELIVERY_COMPANY_STATUSES
    ),

    # 食数・金額
    total_meal_count: Field::Number,
    subtotal: ReadonlyNumberField,
    tax_8_percent: ReadonlyNumberField,
    tax_10_percent: ReadonlyNumberField,
    tax: ReadonlyNumberField,
    delivery_fee: CurrencyField,
    delivery_fee_tax: ReadonlyNumberField,
    discount_amount: CurrencyField,
    total_price: ReadonlyNumberField,

    # 配送フロー
    return_location: Field::String,
    equipment_notes: Field::Text,
    is_trial: Field::Boolean,
    memo: Field::Text,

    # タイムスタンプ
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    company
    restaurant
    scheduled_date
    order_type
    status
    total_meal_count
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    company
    restaurant
    recurring_order
    scheduled_date
    order_type
    status
    order_items
    total_meal_count
    subtotal
    tax
    delivery_fee
    discount_amount
    total_price
    memo
    delivery_plan_items
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    company
    restaurant
    scheduled_date
    order_type
    status
    order_items
    memo
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how orders are displayed
  # across all pages of the admin dashboard.
  def display_resource(order)
    "Order ##{order.id} - #{order.company&.name} - #{order.scheduled_date}"
  end
end

require "administrate/base_dashboard"

class OrderItemDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    order: Field::BelongsTo,
    menu: Field::BelongsTo,
    quantity: Field::Number,
    unit_price: Field::Number.with_options(decimals: 2),
    subtotal: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    order
    menu
    quantity
    subtotal
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    order
    menu
    quantity
    unit_price
    subtotal
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    order
    menu
    quantity
    unit_price
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(order_item)
    "#{order_item.menu&.name} × #{order_item.quantity}"
  end
end

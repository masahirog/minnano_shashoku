require "administrate/base_dashboard"

class DeliveryPlanItemDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    delivery_plan: Field::BelongsTo,
    sequence: Field::Number,
    action_type: Field::Select.with_options(
      collection: ['pickup', 'delivery', 'collection', 'return', 'supply_pickup', 'supply_return']
    ),
    location_type: Field::String,
    location_id: Field::Number,
    scheduled_time: Field::DateTime,
    actual_time: Field::DateTime,
    status: Field::Select.with_options(
      collection: ['pending', 'in_progress', 'completed', 'skipped']
    ),
    meal_count: Field::Number,
    supplies_info: Field::String.with_options(searchable: false),
    notes: Field::Text,
    orders: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    delivery_plan
    sequence
    action_type
    status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    delivery_plan
    sequence
    action_type
    location_type
    location_id
    scheduled_time
    actual_time
    status
    meal_count
    supplies_info
    notes
    orders
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    delivery_plan
    sequence
    action_type
    location_type
    location_id
    scheduled_time
    status
    meal_count
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(delivery_plan_item)
    "#{delivery_plan_item.sequence}. #{delivery_plan_item.action_type}"
  end
end

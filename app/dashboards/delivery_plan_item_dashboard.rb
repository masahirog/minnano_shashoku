require "administrate/base_dashboard"

class DeliveryPlanItemDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    delivery_plan: Field::BelongsTo,
    order: Field::BelongsTo,
    action_type: Field::Select.with_options(
      collection: ::DeliveryPlanItem::ACTION_TYPES
    ),
    restaurant: Field::BelongsTo,
    company: Field::BelongsTo,
    own_location: Field::BelongsTo,
    scheduled_time: Field::DateTime,
    actual_time: Field::DateTime,
    status: Field::Select.with_options(
      collection: ::DeliveryPlanItem::STATUSES
    ),
    notes: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    delivery_plan
    order
    action_type
    status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    delivery_plan
    order
    action_type
    restaurant
    company
    own_location
    scheduled_time
    actual_time
    status
    notes
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    delivery_plan
    order
    action_type
    restaurant
    company
    own_location
    scheduled_time
    status
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(delivery_plan_item)
    "#{delivery_plan_item.action_type_ja} - #{delivery_plan_item.location_name}"
  end
end

require "administrate/base_dashboard"

class DeliveryPlanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    delivery_company: Field::BelongsTo,
    driver: Field::BelongsTo.with_options(class_name: "DeliveryUser"),
    delivery_date: Field::Date,
    status: Field::Select.with_options(
      collection: ['draft', 'confirmed', 'in_progress', 'completed', 'cancelled']
    ),
    started_at: Field::DateTime,
    completed_at: Field::DateTime,
    notes: Field::Text,
    delivery_plan_items: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    delivery_company
    driver
    delivery_date
    status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    delivery_company
    driver
    delivery_date
    status
    started_at
    completed_at
    notes
    delivery_plan_items
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    delivery_company
    driver
    delivery_date
    status
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(delivery_plan)
    "配送計画 ##{delivery_plan.id} - #{delivery_plan.delivery_date}"
  end
end

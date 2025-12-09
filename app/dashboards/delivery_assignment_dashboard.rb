require "administrate/base_dashboard"

class DeliveryAssignmentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    order: Field::BelongsTo,
    delivery_user: Field::BelongsTo,
    delivery_company: Field::BelongsTo,
    scheduled_date: Field::Date,
    scheduled_time: Field::Time,
    sequence_number: Field::Number,
    status: Field::Select.with_options(
      collection: [
        ['準備中', 'pending'],
        ['準備中', 'preparing'],
        ['配送中', 'in_transit'],
        ['完了', 'completed'],
        ['失敗', 'failed']
      ]
    ),
    assigned_at: Field::DateTime,
    delivery_report: Field::HasOne,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    order
    delivery_user
    scheduled_date
    status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    order
    delivery_user
    delivery_company
    scheduled_date
    scheduled_time
    sequence_number
    status
    assigned_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    order
    delivery_user
    delivery_company
    scheduled_date
    scheduled_time
    sequence_number
    status
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(delivery_assignment)
    "配送割当 ##{delivery_assignment.id}"
  end
end

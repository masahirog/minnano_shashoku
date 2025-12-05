require "administrate/base_dashboard"

class DeliveryReportDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    delivery_assignment: Field::BelongsTo,
    delivery_user: Field::BelongsTo,
    report_type: Field::Select.with_options(
      collection: [
        ['完了', 'completed'],
        ['失敗', 'failed'],
        ['問題', 'issue']
      ]
    ),
    started_at: Field::DateTime,
    completed_at: Field::DateTime,
    latitude: Field::Number.with_options(decimals: 7),
    longitude: Field::Number.with_options(decimals: 7),
    notes: Field::Text,
    issue_type: Field::String,
    photos: Field::String,
    signature_data: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    delivery_assignment
    delivery_user
    report_type
    completed_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    delivery_assignment
    delivery_user
    report_type
    started_at
    completed_at
    latitude
    longitude
    notes
    issue_type
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    delivery_assignment
    delivery_user
    report_type
    started_at
    completed_at
    latitude
    longitude
    notes
    issue_type
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(delivery_report)
    "配送報告 ##{delivery_report.id}"
  end
end

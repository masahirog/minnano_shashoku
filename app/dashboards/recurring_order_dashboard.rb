require "administrate/base_dashboard"

class RecurringOrderDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    company: Field::BelongsTo,
    orders: Field::HasMany,

    # Schedule settings
    day_of_week: Field::Select.with_options(
      collection: [['日曜日', 0], ['月曜日', 1], ['火曜日', 2], ['水曜日', 3],
                   ['木曜日', 4], ['金曜日', 5], ['土曜日', 6]]
    ),

    # Order details
    meal_count: Field::Number,
    delivery_time: TimeWithoutSecondsField,
    pickup_time: TimeWithoutSecondsField,

    # Status fields
    is_active: Field::Boolean,
    status: Field::Select.with_options(
      collection: [['有効', 'active'], ['一時停止', 'paused'], ['終了', 'completed']]
    ),
    notes: Field::Text,

    # Timestamps
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    company
    day_of_week
    meal_count
    delivery_time
    status
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    company
    day_of_week
    meal_count
    delivery_time
    pickup_time
    is_active
    status
    notes
    orders
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    company
    day_of_week
    meal_count
    delivery_time
    pickup_time
    status
    notes
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

  # Overwrite this method to customize how recurring orders are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(recurring_order)
    return "新規定期案件" if recurring_order.new_record?
    day_names = %w[日 月 火 水 木 金 土]
    day_text = recurring_order.day_of_week ? "毎#{day_names[recurring_order.day_of_week]}曜日" : "未設定"
    "#{recurring_order.company&.name} - #{day_text}"
  end
end

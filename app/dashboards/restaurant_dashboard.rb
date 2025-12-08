require "administrate/base_dashboard"

class RestaurantDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    closed_days: Field::String,
    contact_email: Field::String,
    contact_person: Field::String,
    contact_phone: Field::String,
    contract_status: Field::String,
    delivery_fee_per_meal: Field::Number,
    genre: Field::String,
    has_delivery_fee: Field::Boolean,
    invoice_number: Field::String,
    max_capacity: Field::Number,
    menus: Field::HasMany,
    name: Field::String,
    orders: Field::HasMany,
    phone: Field::String,
    pickup_address: Field::Text,
    pickup_time_trial_only: Field::String,
    pickup_time_with_main: Field::String,
    self_delivery: Field::Boolean,
    admin_user: Field::BelongsTo,
    supplier_code: Field::String,
    supply_stocks: Field::HasMany,
    trial_available: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    name
    genre
    contract_status
    admin_user
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    admin_user
    genre
    contract_status
    contact_person
    contact_phone
    contact_email
    phone
    supplier_code
    invoice_number
    max_capacity
    pickup_time_with_main
    pickup_time_trial_only
    closed_days
    has_delivery_fee
    delivery_fee_per_meal
    self_delivery
    trial_available
    pickup_address
    menus
    orders
    supply_stocks
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    admin_user
    genre
    contract_status
    contact_person
    contact_phone
    contact_email
    phone
    supplier_code
    invoice_number
    max_capacity
    pickup_time_with_main
    pickup_time_trial_only
    closed_days
    has_delivery_fee
    delivery_fee_per_meal
    self_delivery
    trial_available
    pickup_address
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

  # Overwrite this method to customize how restaurants are displayed
  # across all pages of the admin dashboard.
  def display_resource(restaurant)
    restaurant.name
  end
end

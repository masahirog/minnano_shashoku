require "administrate/base_dashboard"

class DeliveryUserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::String,
    name: Field::String,
    phone: Field::String,
    role: Field::Select.with_options(
      collection: [['管理者', 'admin'], ['ドライバー', 'driver']]
    ),
    delivery_company: Field::BelongsTo,
    is_active: Field::Boolean,
    last_sign_in_at: Field::DateTime,
    sign_in_count: Field::Number,
    current_sign_in_at: Field::DateTime,
    current_sign_in_ip: Field::String,
    last_sign_in_ip: Field::String,
    delivery_assignments: Field::HasMany,
    delivery_reports: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    password: Field::Password,
    password_confirmation: Field::Password,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    name
    email
    delivery_company
    role
    is_active
    last_sign_in_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    name
    phone
    role
    delivery_company
    is_active
    sign_in_count
    current_sign_in_at
    last_sign_in_at
    current_sign_in_ip
    last_sign_in_ip
    delivery_assignments
    delivery_reports
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    email
    name
    phone
    role
    delivery_company
    is_active
    password
    password_confirmation
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
  COLLECTION_FILTERS = {
    active: ->(resources) { resources.active },
    inactive: ->(resources) { resources.inactive },
    drivers: ->(resources) { resources.drivers },
    admins: ->(resources) { resources.admins },
  }.freeze

  # Overwrite this method to customize how delivery users are displayed
  # across all pages of the admin dashboard.
  def display_resource(delivery_user)
    "#{delivery_user.name} (#{delivery_user.email})"
  end
end

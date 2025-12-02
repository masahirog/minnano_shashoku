require "administrate/base_dashboard"

class SupplyStockDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    last_updated_at: Field::DateTime,
    location: Field::Polymorphic,
    location_name: Field::String,
    location_type_detail: Field::String,
    physical_count: Field::String.with_options(searchable: false),
    quantity: Field::String.with_options(searchable: false),
    supply: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    supply
    location_name
    quantity
    last_updated_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    supply
    location
    location_name
    location_type_detail
    quantity
    physical_count
    last_updated_at
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    supply
    location
    location_name
    location_type_detail
    quantity
    physical_count
    last_updated_at
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

  # Overwrite this method to customize how supply stocks are displayed
  # across all pages of the admin dashboard.
  def display_resource(supply_stock)
    "#{supply_stock.supply&.name} - #{supply_stock.location_name}"
  end
end

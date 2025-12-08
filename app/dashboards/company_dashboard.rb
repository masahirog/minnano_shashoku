require "administrate/base_dashboard"

class CompanyDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    billing_dept: Field::String,
    billing_email: Field::String,
    billing_person_name: Field::String,
    billing_person_title: Field::String,
    color: Field::String,
    contact_email: Field::String,
    contact_person: Field::String,
    contact_phone: Field::String,
    contract_status: Field::String,
    contract_end_date: Field::Date,
    default_meal_count: Field::Number,
    delivery_address: Field::Text,
    delivery_day_of_week: Field::String,
    delivery_fee_campaign_end_date: Field::Date,
    delivery_fee_discount: Field::Number,
    delivery_notes: Field::Text,
    delivery_time_goal: Field::String,
    digital_signage_id: Field::String,
    discount_amount: Field::Number,
    discount_campaign_end_date: Field::Date,
    discount_type: Field::String,
    employee_burden_amount: Field::Number,
    employee_burden_enabled: Field::Boolean,
    first_delivery_date: Field::Date,
    formal_name: Field::String,
    has_setup: Field::Boolean,
    initial_fee_amount: Field::Number,
    initial_fee_waived: Field::Boolean,
    monthly_fee_type: Field::String,
    name: Field::String,
    orders: Field::HasMany,
    recurring_orders: NestedHasManyField,
    paypay_employee_rate_1: Field::Number,
    paypay_employee_rate_2: Field::Number,
    paypay_enabled: Field::Boolean,
    pickup_notes: Field::Text,
    pickup_time_goal: Field::String,
    remote_delivery_fee: Field::Number,
    special_delivery_fee: Field::Number,
    admin_user: Field::BelongsTo,
    supply_stocks: Field::HasMany,
    trial_billable: Field::Boolean,
    trial_date: Field::Date,
    trial_free_meal_count: Field::Number,
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
    formal_name
    contract_status
    admin_user
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    formal_name
    admin_user
    contract_status
    color
    contact_person
    contact_phone
    contact_email
    delivery_address
    billing_email
    billing_dept
    billing_person_title
    billing_person_name
    default_meal_count
    delivery_day_of_week
    delivery_time_goal
    pickup_time_goal
    has_setup
    first_delivery_date
    paypay_enabled
    paypay_employee_rate_1
    paypay_employee_rate_2
    employee_burden_enabled
    employee_burden_amount
    discount_type
    discount_amount
    discount_campaign_end_date
    delivery_fee_discount
    delivery_fee_campaign_end_date
    monthly_fee_type
    initial_fee_amount
    initial_fee_waived
    remote_delivery_fee
    special_delivery_fee
    trial_billable
    trial_date
    trial_free_meal_count
    digital_signage_id
    delivery_notes
    pickup_notes
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
    formal_name
    admin_user
    contract_status
    first_delivery_date
    contract_end_date
    recurring_orders
    color
    contact_person
    contact_phone
    contact_email
    delivery_address
    billing_email
    billing_dept
    billing_person_title
    billing_person_name
    default_meal_count
    delivery_day_of_week
    delivery_time_goal
    pickup_time_goal
    has_setup
    paypay_enabled
    paypay_employee_rate_1
    paypay_employee_rate_2
    employee_burden_enabled
    employee_burden_amount
    discount_type
    discount_amount
    discount_campaign_end_date
    delivery_fee_discount
    delivery_fee_campaign_end_date
    monthly_fee_type
    initial_fee_amount
    initial_fee_waived
    remote_delivery_fee
    special_delivery_fee
    trial_billable
    trial_date
    trial_free_meal_count
    digital_signage_id
    delivery_notes
    pickup_notes
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

  # Overwrite this method to customize how companies are displayed
  # across all pages of the admin dashboard.
  def display_resource(company)
    company.name
  end
end

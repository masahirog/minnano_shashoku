require "administrate/base_dashboard"

class InvoiceDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    billing_period_end: Field::Date,
    billing_period_start: Field::Date,
    company: Field::BelongsTo,
    invoice_items: Field::HasMany,
    invoice_number: Field::String,
    issue_date: Field::Date,
    notes: Field::Text,
    orders: Field::HasMany,
    payment_due_date: Field::Date,
    payment_status: Field::String,
    payments: Field::HasMany,
    status: Field::String,
    subtotal: Field::Number,
    tax_amount: Field::Number,
    total_amount: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    invoice_number
    company
    issue_date
    total_amount
    status
    payment_status
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    billing_period_end
    billing_period_start
    company
    invoice_items
    invoice_number
    issue_date
    notes
    orders
    payment_due_date
    payment_status
    payments
    status
    subtotal
    tax_amount
    total_amount
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    billing_period_end
    billing_period_start
    company
    invoice_items
    invoice_number
    issue_date
    notes
    orders
    payment_due_date
    payment_status
    payments
    status
    subtotal
    tax_amount
    total_amount
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

  # Overwrite this method to customize how invoices are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(invoice)
    "請求書 #{invoice.invoice_number}"
  end
end

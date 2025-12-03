FactoryBot.define do
  factory :invoice do
    company { nil }
    invoice_number { "MyString" }
    issue_date { "2025-12-03" }
    payment_due_date { "2025-12-03" }
    billing_period_start { "2025-12-03" }
    billing_period_end { "2025-12-03" }
    subtotal { 1 }
    tax_amount { 1 }
    total_amount { 1 }
    status { "MyString" }
    payment_status { "MyString" }
    notes { "MyText" }
  end
end

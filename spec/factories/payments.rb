FactoryBot.define do
  factory :payment do
    invoice { nil }
    payment_date { "2025-12-04" }
    amount { 1 }
    payment_method { "MyString" }
    reference_number { "MyString" }
    notes { "MyText" }
  end
end

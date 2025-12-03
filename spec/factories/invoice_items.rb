FactoryBot.define do
  factory :invoice_item do
    invoice { nil }
    order { nil }
    description { "MyString" }
    quantity { 1 }
    unit_price { 1 }
    amount { 1 }
  end
end

FactoryBot.define do
  factory :supply_inventory do
    supply { nil }
    location_type { "MyString" }
    location_id { "" }
    inventory_date { "2025-12-05" }
    theoretical_quantity { "9.99" }
    actual_quantity { "9.99" }
    difference { "9.99" }
    notes { "MyText" }
    admin_user { nil }
  end
end

FactoryBot.define do
  factory :supply_stock do
    association :supply
    location_type { nil }
    location_id { nil }
    location_name { ['本社', '倉庫A', '倉庫B', '試食会会場'].sample }
    quantity { rand(0..100) }
    physical_count { nil }
    last_updated_at { Time.current }

    trait :headquarters do
      location_name { '本社' }
    end

    trait :warehouse_a do
      location_name { '倉庫A' }
    end

    trait :warehouse_b do
      location_name { '倉庫B' }
    end

    trait :low_stock do
      quantity { 5 }
    end

    trait :out_of_stock do
      quantity { 0 }
    end

    trait :high_stock do
      quantity { 100 }
    end

    trait :with_physical_count do
      physical_count { rand(0..100) }
    end

    trait :with_company_location do
      location_type { 'Company' }
      association :location, factory: :company
    end

    # Polymorphic association helper
    transient do
      location { nil }
    end

    after(:build) do |supply_stock, evaluator|
      if evaluator.location
        supply_stock.location = evaluator.location
      end
    end
  end
end

FactoryBot.define do
  factory :supply_movement do
    association :supply
    movement_type { '入荷' }
    quantity { rand(10..100) }
    movement_date { Date.today }
    from_location_type { nil }
    from_location_id { nil }
    from_location_name { nil }
    to_location_type { nil }
    to_location_id { nil }
    to_location_name { '本社' }
    notes { 'テスト用の在庫移動' }

    trait :arrival do
      movement_type { '入荷' }
      from_location_type { nil }
      from_location_id { nil }
      from_location_name { nil }
      to_location_name { '本社' }
    end

    trait :consumption do
      movement_type { '消費' }
      from_location_name { '本社' }
      to_location_type { nil }
      to_location_id { nil }
      to_location_name { nil }
    end

    trait :transfer do
      movement_type { '移動' }
      from_location_name { '本社' }
      to_location_name { '倉庫A' }
    end

    trait :to_company do
      movement_type { '移動' }
      from_location_name { '本社' }
      to_location_type { 'Company' }
      association :to_location, factory: :company
    end

    trait :from_company do
      movement_type { '移動' }
      from_location_type { 'Company' }
      association :from_location, factory: :company
      to_location_name { '本社' }
    end

    # Polymorphic association helpers
    transient do
      from_location { nil }
      to_location { nil }
    end

    after(:build) do |movement, evaluator|
      if evaluator.from_location
        movement.from_location = evaluator.from_location
      end
      if evaluator.to_location
        movement.to_location = evaluator.to_location
      end
    end
  end
end

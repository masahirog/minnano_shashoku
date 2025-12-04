FactoryBot.define do
  factory :supply do
    sequence(:name) { |n| "テスト備品#{n}" }
    sequence(:sku) { |n| "TEST-#{n.to_s.rjust(4, '0')}" }
    category { ['使い捨て備品', '企業貸与備品', '飲食店貸与備品'].sample }
    unit { ['個', 'セット', 'パック', '本'].sample }
    reorder_point { rand(10..50) }
    storage_guideline { '直射日光を避けて保管してください' }
    is_active { true }

    trait :disposable do
      category { '使い捨て備品' }
      unit { '個' }
    end

    trait :company_loan do
      category { '企業貸与備品' }
      unit { 'セット' }
    end

    trait :restaurant_loan do
      category { '飲食店貸与備品' }
      unit { 'セット' }
    end

    trait :inactive do
      is_active { false }
    end

    trait :with_stocks do
      after(:create) do |supply|
        create_list(:supply_stock, 3, supply: supply)
      end
    end

    trait :with_movements do
      after(:create) do |supply|
        create_list(:supply_movement, 5, supply: supply)
      end
    end
  end
end

FactoryBot.define do
  factory :delivery_user do
    sequence(:email) { |n| "delivery_user_#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:name) { |n| "配送担当者#{n}" }
    phone { "090-1234-5678" }
    role { "driver" }
    is_active { true }
    association :delivery_company

    trait :admin do
      role { "admin" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :with_assignments do
      after(:create) do |delivery_user|
        create_list(:delivery_assignment, 3, delivery_user: delivery_user)
      end
    end
  end
end

FactoryBot.define do
  factory :restaurant do
    name { Faker::Restaurant.name }
    pickup_address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.phone_number }
    contract_status { 'active' }
    max_capacity { 100 }
    capacity_per_day { 100 }
    max_lots_per_day { 2 }
    regular_holiday { nil }
  end
end

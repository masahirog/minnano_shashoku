FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    formal_name { Faker::Company.name }
    contract_status { 'active' }
    delivery_address { Faker::Address.full_address }
    default_meal_count { 40 }
  end
end

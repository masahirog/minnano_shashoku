FactoryBot.define do
  factory :menu do
    association :restaurant
    name { Faker::Food.dish }
    price_per_meal { 649 }
    is_active { true }
  end
end

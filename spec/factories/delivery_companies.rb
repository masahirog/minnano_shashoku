FactoryBot.define do
  factory :delivery_company do
    name { Faker::Company.name }
    phone { Faker::PhoneNumber.phone_number }
    is_active { true }
  end
end

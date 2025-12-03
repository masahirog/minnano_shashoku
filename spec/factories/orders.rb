FactoryBot.define do
  factory :order do
    association :company
    association :restaurant
    association :menu
    association :delivery_company

    order_type { 'manual' }
    scheduled_date { Date.today + 1.week }
    default_meal_count { 50 }
    status { 'pending' }
  end
end

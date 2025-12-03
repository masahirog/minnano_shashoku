FactoryBot.define do
  factory :recurring_order do
    association :company
    association :restaurant
    association :menu
    association :delivery_company

    day_of_week { 1 } # 月曜日
    frequency { 'weekly' }
    start_date { Date.today }
    end_date { nil }
    default_meal_count { 50 }
    delivery_time { '12:00' }
    pickup_time { '10:00' }

    is_trial { false }
    collection_time { '14:00' }
    warehouse_pickup_time { '09:00' }
    return_location { 'warehouse' }
    equipment_notes { nil }

    is_active { true }
    status { 'active' }
    notes { nil }
  end
end

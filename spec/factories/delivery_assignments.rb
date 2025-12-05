FactoryBot.define do
  factory :delivery_assignment do
    association :order
    association :delivery_user
    association :delivery_company
    scheduled_date { Date.current }
    scheduled_time { Time.zone.parse("10:00") }
    sequence_number { 1 }
    status { "pending" }
    assigned_at { Time.current }

    trait :preparing do
      status { "preparing" }
    end

    trait :in_transit do
      status { "in_transit" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :with_report do
      after(:create) do |assignment|
        create(:delivery_report, delivery_assignment: assignment, delivery_user: assignment.delivery_user)
      end
    end
  end
end

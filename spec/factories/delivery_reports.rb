FactoryBot.define do
  factory :delivery_report do
    association :delivery_assignment
    association :delivery_user
    report_type { "completed" }
    started_at { 2.hours.ago }
    completed_at { 1.hour.ago }
    latitude { 35.6812 }
    longitude { 139.7671 }
    notes { "配送完了しました" }

    trait :failed do
      report_type { "failed" }
      issue_type { "absent" }
      notes { "不在のため配送できませんでした" }
    end

    trait :issue do
      report_type { "issue" }
      issue_type { "address_unknown" }
      notes { "住所が見つかりませんでした" }
    end

    trait :with_photos do
      photos { ["/uploads/photo1.jpg", "/uploads/photo2.jpg"] }
    end
  end
end

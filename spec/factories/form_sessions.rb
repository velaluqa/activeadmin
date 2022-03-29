FactoryBot.define do
  factory :form_session do
    sequence(:name) { |n| puts n; "Test Session #{n}" }
    description { "" }
  end
end

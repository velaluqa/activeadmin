FactoryBot.define do
  factory :form_definition do
    sequence(:name) { |n| "Test Form #{n}" }
    description { "" }
  end
end

FactoryBot.define do
  factory :form_definition do
    sequence(:name) { |n| "TestForm##{n}" }
    description { "" }
  end
end

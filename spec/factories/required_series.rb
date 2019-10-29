FactoryBot.define do
  factory :required_series do
    visit
    sequence(:name) { |n| "image_series#{n}" }
  end
end

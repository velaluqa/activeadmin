FactoryGirl.define do
  factory :notification_profile do
    title { Faker::Lorem.sentence(3, false, 3) }
    description nil
    notification_type nil

    triggering_action 'all'
    triggering_resource 'Visit'

    filters([])

    only_authorized_recipients true

    is_active true
  end
end

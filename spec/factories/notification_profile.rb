FactoryGirl.define do
  factory :notification_profile do
    title { Faker::Lorem.sentence(3, false, 3) }
    description nil
    notification_type nil

    triggering_actions %w(create update destroy)
    triggering_resource 'Visit'

    filters([])

    only_authorized_recipients true

    email_template

    is_enabled true
  end
end

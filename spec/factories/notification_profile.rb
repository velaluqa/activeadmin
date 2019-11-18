FactoryBot.define do
  factory :notification_profile do
    title { Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 3) }
    description { nil }
    notification_type { nil }

    triggering_actions { %w[create update destroy] }
    triggering_resource { 'Visit' }

    filters { [] }

    only_authorized_recipients { true }

    email_template

    is_enabled { true }
  end
end

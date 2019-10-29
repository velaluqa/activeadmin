FactoryBot.define do
  factory :visit do
    patient
    sequence :visit_number
    sequence(:domino_unid) do |n|
      '00BEEAFBEC35CFF7C12578CC00517D20'[0..-n.to_s.length] + n.to_s
    end

    trait :without_notification_callbacks do
      # Disable notification callbacks when creating factory objects.
      after(:build) do |object|
        class << object; def notification_observable_create
                           true
                         end; end
        class << object; def notification_observable_update
                           true
                         end; end
        class << object; def notification_observable_destroy
                           true
                         end; end
      end
    end
  end
end

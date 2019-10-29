FactoryBot.define do
  factory :email_template do
    sequence(:name) { |n| "Email Template #{n}" }
    email_type { 'NotificationProfile' }
    template { 'Some template' }
  end
end

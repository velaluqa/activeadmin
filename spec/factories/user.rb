FactoryGirl.define do
  factory :user do
    username { Faker::Internet.user_name }
    password 'password'

    trait :changed_password do
      password_changed_at DateTime.now
    end

    trait :with_role do
      transient do
        role :manage
        subject_type nil
      end

      after :create do |user, evaluator|
        create :role,
               role: evaluator.role,
               user: user,
               subject_type: evaluator.subject_type
      end
    end
  end
end

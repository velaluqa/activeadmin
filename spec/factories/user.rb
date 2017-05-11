FactoryGirl.define do
  factory :user do
    transient do
      with_user_roles([])
    end

    name { Faker::Name.name }
    username { |u| Faker::Internet.user_name(u.name, %w[. _ -]) }
    password 'password'
    email { |_u| Faker::Internet.safe_email }

    confirmed_at { DateTime.now }

    trait :changed_password do
      password_changed_at DateTime.now
    end

    trait :with_keypair do
      after(:create) do |user|
        user.generate_keypair('password')
      end
    end

    before(:create) do |user, evaluator|
      evaluator.with_user_roles.each do |role_obj|
        case role_obj
        when Array
          role, scope = role_obj
          user.user_roles << UserRole.new(role: role, scope_object: scope)
        when Hash
          user.user_roles << UserRole.new(role_obj)
        else
          user.user_roles << UserRole.new(role: role_obj)
        end
      end
    end
  end
end

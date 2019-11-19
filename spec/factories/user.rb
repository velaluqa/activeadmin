FactoryBot.define do
  factory :user do
    transient do
      with_user_roles { [] }
    end

    name { Faker::Name.name }
    username do |u|
      Faker::Internet.user_name(
        specifier: u.name,
        separators: %w[. _ -]
      )
    end
    password { 'password' }
    sequence(:email) do |n|
      "person#{n}@example.com"
    end

    confirmed_at { DateTime.now }

    trait :changed_password do
      password_changed_at { DateTime.now }
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

FactoryGirl.define do
  factory :public_key do
    user
    public_key 'Some Public Key'
    active true

    trait :active do
      active true
    end

    trait :deactivated do
      active false
      deactivated_at { DateTime.now }
    end
  end
end

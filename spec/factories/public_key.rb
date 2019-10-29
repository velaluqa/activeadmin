FactoryBot.define do
  factory :public_key do
    user
    public_key 'Some Public Key'
    active true

    before(:create) do |public_key|
      return unless public_key.active?
      public_key.user.public_keys.active.each(&:deactivate)
    end

    trait :active do
      active true
    end

    trait :deactivated do
      active false
      deactivated_at { DateTime.now }
    end
  end
end

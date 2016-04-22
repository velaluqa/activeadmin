FactoryGirl.define do
  factory :role do
    user
    role :manage
    subject_type 'System'
  end
end

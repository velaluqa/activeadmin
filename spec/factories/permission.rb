FactoryGirl.define do
  factory :permission do
    role
    activity { %w[manage read update create destroy].sample }
    subject { %w[Study Center Patient].sample }
  end
end

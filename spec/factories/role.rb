FactoryGirl.define do
  factory :role do
    transient do
      with_permissions({})
    end

    title { Faker::Lorem.words(2).join(' ') }

    before(:create) do |role, evaluator|
      evaluator.with_permissions.each_pair do |activity, subjects|
        Array[subjects].flatten.each do |subject|
          role.permissions << Permission.new(activity: activity, subject: subject)
        end
      end
    end
  end
end

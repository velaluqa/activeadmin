FactoryGirl.define do
  factory :role do
    transient do
      with_permissions({})
    end

    title { Faker::Lorem.words(2).join(' ') }

    before(:create) do |role, evaluator|
      evaluator.with_permissions.each_pair do |subjects, activities|
        Array[subjects].flatten.each do |subject|
          Array[activities].flatten.each do |activity|
            role.permissions << Permission.new(
              activity: activity,
              subject: subject
            )
          end
        end
      end
    end
  end
end

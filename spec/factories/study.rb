FactoryGirl.define do
  factory :study do
    name { Faker::Lorem.sentence(2, false, 0) }

    trait :production do
      state Study.state_sym_to_int(:production)
    end

    trait :building do
      state Study.state_sym_to_int(:building)
    end

    trait :with_centers do
      transient do
        centers_count 3
      end

      after :create do |study, evaluator|
        create_list :center, evaluator.centers_count, study: study
      end
    end
  end
end

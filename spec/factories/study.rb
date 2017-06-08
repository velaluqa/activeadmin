FactoryGirl.define do
  factory :study do
    sequence(:name) { |n| "Study #{n}" }

    transient do
      configuration(nil)
    end

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

    after(:create) do |study, evaluator|
      if evaluator.configuration.is_a?(String)
        study.update_configuration!(evaluator.configuration)
      end
    end
  end
end

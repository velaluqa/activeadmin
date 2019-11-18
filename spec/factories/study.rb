FactoryBot.define do
  factory :study do
    sequence(:name) { |n| "Study #{n}" }

    transient do
      configuration { nil }
    end

    trait :production do
      state { Study.state_sym_to_int(:production) }
    end

    trait :building do
      state { Study.state_sym_to_int(:building) }
    end

    trait :with_centers do
      transient do
        centers_count { 3 }
      end

      after :create do |study, evaluator|
        create_list :center, evaluator.centers_count, study: study
      end
    end

    after(:create) do |study, evaluator|
      if evaluator.configuration.is_a?(String)
        temp_file = Tempfile.new.tap do |file|
          file.write(evaluator.configuration)
          file.close
        end

        result = Study::UploadConfiguration.(
          params: {
            id: study.id,
            'study_contract_upload_configuration' => {
              id: study.id,
              file: Rack::Test::UploadedFile.new(temp_file.path)
            }
          }
        )

        raise result['contract.default'].errors.messages.inspect unless result.success?
      end
    end

    trait :locked do
      after(:create) do |study, evaluator|
        study.lock_configuration!
      end
    end
  end
end

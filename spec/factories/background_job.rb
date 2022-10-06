FactoryBot.define do
  factory :background_job do
    user
    completed { false }

    name { Faker::Lorem.words(number: 3) }

    trait :running do
      state { :running }
    end

    trait :cancelling do
      state { :cancelling }
    end

    trait :cancelled do
      state { :cancelled }
    end

    trait :successful do
      progress { 1.0 }
      completed_at { DateTime.now }
      state { :successful }
    end

    trait :failed do
      completed_at { DateTime.now }
      state { :failed }
    end

    trait :with_zipfile do
      before(:create) do |job|
        file = 'spec/tmp/background_job_results.zip'
        FileUtils.touch(file)
        job.results ||= {}
        job.results['zipfile'] = file
      end
    end
  end
end

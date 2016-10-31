FactoryGirl.define do
  factory :background_job do
    user
    completed false

    name { Faker::Lorem.words(3) }

    trait :complete do
      completed true
      progress 1.0
      completed_at { DateTime.now }
    end

    trait :successful do
      successful true
    end

    trait :failed do
      successful false
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

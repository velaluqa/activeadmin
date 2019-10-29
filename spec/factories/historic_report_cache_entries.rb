FactoryBot.define do
  factory :historic_report_cache_entry do
    historic_report_query
    study
    date { DateTime.now }
  end
end

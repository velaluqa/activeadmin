FactoryGirl.define do
  factory :historic_report_cache_value do
    historic_report_cache_entry
    group(nil)
    count(1)
    delta(-1)
  end
end

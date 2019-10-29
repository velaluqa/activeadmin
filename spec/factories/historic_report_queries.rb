FactoryBot.define do
  factory :historic_report_query do
    resource_type('Patient')
    group_by(nil)
  end
end

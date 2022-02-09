FactoryBot.define do
  factory :configuration do
    schema_spec { "formio_v1" }
    configurable { create(:form_definition) }
    payload { "" }
  end
end

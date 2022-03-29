FactoryBot.define do
  factory :form_answer do
    form_definition
    configuration
    public_key
    is_test_data { false }
    is_obsolete { false }
  end
end

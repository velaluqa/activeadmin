# ## Schema Information
#
# Table name: `form_definitions`
#
# ### Columns
#
# Name                            | Type               | Attributes
# ------------------------------- | ------------------ | ---------------------------
# **`created_at`**                | `datetime`         | `not null`
# **`current_configuration_id`**  | `uuid`             |
# **`description`**               | `text`             | `not null`
# **`id`**                        | `uuid`             | `not null, primary key`
# **`locked_at`**                 | `datetime`         |
# **`locked_configuration_id`**   | `uuid`             |
# **`name`**                      | `string`           | `not null`
# **`updated_at`**                | `datetime`         | `not null`
#

FactoryBot.define do
  factory :form_definition do
    sequence(:name) { |n| "Test Form #{n}" }
    description { "" }

    transient do
      configuration { nil }
    end

    after :create do |form_definition, evaluator|
      if evaluator.configuration.present?
        previous_configuration = form_definition.configuration
        data = {}
        data = previous_configuration.data if previous_configuration

        test_form_data = JSON.parse(File.read("spec/files/#{evaluator.configuration}"))

        data["layout"] = test_form_data["layout"]

        new_configuration = Configuration.create(
          previous_configuration_id: previous_configuration.andand.id,
          configurable: form_definition,
          schema_spec: 'formio_v1',
          payload: JSON.dump(data)
        )
        form_definition.current_configuration = new_configuration
        form_definition.save
      end
    end
  end
end

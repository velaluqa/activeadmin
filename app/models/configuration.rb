class Configuration < ApplicationRecord
  has_paper_trail(
    class_name: 'Version',
    meta: {
      form_definition_id: ->(configuration) {
        configuration.configurable_id if configuration.configurable_type == "FormDefinition"
      },
      configuration_id: ->(configuration) { configuration.id }
    }
  )

  has_one(
    :form_definition,
    foreign_key: :current_configuration_id
  )
  belongs_to(
    :configurable,
    polymorphic: true
  )
  has_many(
    :form_answers,
    foreign_key: :configuration_id
  )

  belongs_to(
    :previous_configuration,
    class_name: "Configuration",
    optional: true
  )

  def data
    JSON.parse(payload[0] == "{" ? payload : "{}")
  end

  def data=(data)
    self.payload = JSON.dump(data)
  end
end

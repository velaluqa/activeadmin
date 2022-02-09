class FormDefinition < ApplicationRecord
  has_paper_trail(
    class_name: 'Version',
    meta: {
      form_definition_id: :id,
      configuration_id: ->(form_definition) {
        form_definition.current_configuration_id
      }
    }
  )

  has_many :form_answers
  belongs_to(                   #
    :current_configuration,
    class_name: "Configuration",
    foreign_key: :current_configuration_id,
    optional: true
  )
  belongs_to(
    :locked_configuration,
    class_name: "Configuration",
    foreign_key: :locked_configuration_id,
    optional: true
  )

  def configuration
    locked_configuration || current_configuration
  end
end

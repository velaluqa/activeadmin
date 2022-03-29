class FormDefinition < ApplicationRecord
  include ConfigurationPathAccessor

  VALIDATION_VALUES = { none: "none", optional: "optional", required: "required" }.freeze
  LISTING_VALUES = { all: "all", assigned: "assigned", authorized: "authorized" }.freeze
  RESOURCE_TYPES = %w[any User Study Center Patient Visit RequiredSeries ImageSeries FormAnswer FormSession].freeze
  SEQUENCE_SCOPE_VALUES = %w[any user resource form_session form_definition].freeze

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
  belongs_to(
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

  # This checks the path accessors from the configuration in order to
  # update the configuration via form definitions active admin form.
  before_save :create_configuration_from_dirty

  attr_configuration_path_accessor :validates_study_id, %w[config form_answers validates_study_id], default: "none"
  attr_configuration_path_accessor :validates_form_session_id, %w[config form_answers validates_form_session_id], default: "none"
  attr_configuration_path_accessor :validates_resource_id, %w[config form_answers validates_resource_id], default: "none"
  attr_configuration_path_accessor :validates_user_id, %w[config form_answers validates_user_id], default: "none"
  attr_configuration_path_accessor :validates_resource_type, %w[config form_answers validates_resource_type], default: "any"
  attr_configuration_path_accessor :allow_saving_draft, %w[config form_answers allow_saving_draft], default: false

  attr_configuration_path_accessor :layout, %w[layout], default: {}

  validates :name, presence: true, uniqueness: true, length: { minimum: 4 }
  validates :validates_study_id, inclusion: { in: VALIDATION_VALUES.values }
  validates :validates_form_session_id, inclusion: { in: VALIDATION_VALUES.values }
  validates :validates_resource_id, inclusion: { in: VALIDATION_VALUES.values }
  validates :validates_resource_type, inclusion: { in: RESOURCE_TYPES }
  validates :validates_user_id, inclusion: { in: VALIDATION_VALUES.values }

  def configuration
    locked_configuration || current_configuration
  end

  def free_form?
    validates_study_id == "none" &&
      validates_form_session_id == "none" &&
      validates_resource_id == "none" &&
      validates_user_id == "none"
  end

  private

  def create_configuration_from_dirty
    return unless @configuration_dirty
    @configuration_dirty = false

    previous_configuration = configuration
    data = {}
    data = previous_configuration.data if previous_configuration
    data["config"] ||= {}
    data["config"]["form_answers"] ||= {}
    data["config"]["form_answers"]["validates_study_id"] = validates_study_id
    data["config"]["form_answers"]["validates_form_session_id"] = validates_form_session_id
    data["config"]["form_answers"]["validates_user_id"] = validates_user_id
    data["config"]["form_answers"]["validates_resource_id"] = validates_resource_id
    data["config"]["form_answers"]["validates_resource_type"] = validates_resource_type
    data["config"]["form_answers"]["allow_saving_draft"] = allow_saving_draft == "1"

    new_configuration = Configuration.create(
      previous_configuration_id: previous_configuration.andand.id,
      configurable: self,
      schema_spec: 'formio_v1',
      payload: JSON.dump(data)
    )
    self.current_configuration = new_configuration
  end
end

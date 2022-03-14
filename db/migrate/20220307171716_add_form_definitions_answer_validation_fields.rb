class AddFormDefinitionsAnswerValidationFields < ActiveRecord::Migration[5.2]
  def change
    create_enum :form_definition_validation_value_type, %w[none optional required]
    create_enum :form_definition_listing_value_type, %w[all assigned authorized]

    add_column(
      :form_definitions,
      :sequence_scope,
      :jsonb,
      null: false,
      default: "any"
    )
    add_column(
      :form_definitions,
      :listing,
      :form_definition_listing_value_type,
      null: false,
      index: true,
      default: "authorized"
    )
    add_column(
      :form_definitions,
      :validates_user_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    add_column(
      :form_definitions,
      :validates_study_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    add_column(
      :form_definitions,
      :validates_form_session_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    add_column(
      :form_definitions,
      :validates_resource_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    add_column(
      :form_definitions,
      :validates_resource_type,
      :string,
      null: false,
      default: "any"
    )
  end
end

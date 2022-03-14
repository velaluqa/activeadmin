class RemoveConfigurableFormAnswerValidationColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column(
      :form_definitions,
      :sequence_scope,
      :jsonb,
      null: false,
      default: "any"
    )
    remove_column(
      :form_definitions,
      :listing,
      :form_definition_listing_value_type,
      null: false,
      index: true,
      default: "authorized"
    )
    remove_column(
      :form_definitions,
      :validates_user_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    remove_column(
      :form_definitions,
      :validates_study_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    remove_column(
      :form_definitions,
      :validates_form_session_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    remove_column(
      :form_definitions,
      :validates_resource_id,
      :form_definition_validation_value_type,
      null: false,
      default: "none"
    )
    remove_column(
      :form_definitions,
      :validates_resource_type,
      :string,
      null: false,
      default: "any"
    )

    drop_enum :form_definition_validation_value_type
    drop_enum :form_definition_listing_value_type
  end
end

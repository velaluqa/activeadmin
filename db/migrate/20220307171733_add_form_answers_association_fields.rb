class AddFormAnswersAssociationFields < ActiveRecord::Migration[5.2]
  def change
    add_column :form_answers, :user_id, :integer, null: true, index: true
    add_column :form_answers, :study_id, :integer, null: true, index: true
    add_column :form_answers, :form_session_id, :integer, null: true, index: true
    add_column :form_answers, :form_display_type_id, :integer, null: true, index: true
    add_column :form_answers, :published_at, :datetime, index: true
    add_column :form_answers, :sequence_number, :integer, null: false, index: true, default: 0

    create_table :form_answer_resources do |t|
      t.string :form_answer_id, null: false, index: true
      t.string :resource_id, null: false
      t.string :resource_type, null: false
    end

    add_index :form_answer_resources, %i[form_answer_id resource_id resource_type], unique: true, name: "form_answer_resources_primary_key_index"
    add_index :form_answer_resources, %i[resource_id resource_type], name: "form_answer_resources_resource_index"

  end
end

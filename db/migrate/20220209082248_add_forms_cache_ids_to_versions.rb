class AddFormsCacheIdsToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :form_definition_id, :uuid, null: true, index: true
    add_column :versions, :form_answer_id, :uuid, null: true, index: true
    add_column :versions, :configuration_id, :uuid, null: true, index: true
  end
end

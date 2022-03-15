class ConvertFormAnswerResourcesFormAnswerIdToUuid < ActiveRecord::Migration[5.2]
  def up
    change_column :form_answer_resources, :form_answer_id, 'uuid USING form_answer_id::uuid'
  end

  def down
    change_column :form_answer_resources, :form_answer_id, :string
  end
end

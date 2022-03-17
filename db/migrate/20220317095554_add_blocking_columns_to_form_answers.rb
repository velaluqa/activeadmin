class AddBlockingColumnsToFormAnswers < ActiveRecord::Migration[5.2]
  def change
    add_column :form_answers, :blocking_user_id, :integer, index: true
    add_column :form_answers, :blocked_at, :datetime
  end
end

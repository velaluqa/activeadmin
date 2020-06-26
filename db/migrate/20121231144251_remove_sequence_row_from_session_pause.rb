class RemoveSequenceRowFromSessionPause < ActiveRecord::Migration[4.2]
  def up
    remove_column :session_pauses, :sequence_row
  end

  def down
    add_column :session_pauses, :sequence_row, :integer
  end
end

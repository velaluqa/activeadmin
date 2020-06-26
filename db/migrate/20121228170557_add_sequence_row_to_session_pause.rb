class AddSequenceRowToSessionPause < ActiveRecord::Migration[4.2]
  def change
    add_column :session_pauses, :sequence_row, :integer
  end
end

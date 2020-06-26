class MovePatientToCenter < ActiveRecord::Migration[4.2]
  def up
    remove_column :patients, :session_id
    add_column :patients, :center_id, :integer
  end

  def down
    add_column :patients, :session_id, :integer
    remove_column :patients, :center_id
  end
end

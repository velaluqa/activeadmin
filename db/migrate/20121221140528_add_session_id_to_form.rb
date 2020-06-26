class AddSessionIdToForm < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :session_id, :integer
  end
end

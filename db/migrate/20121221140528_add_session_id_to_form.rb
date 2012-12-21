class AddSessionIdToForm < ActiveRecord::Migration
  def change
    add_column :forms, :session_id, :integer
  end
end

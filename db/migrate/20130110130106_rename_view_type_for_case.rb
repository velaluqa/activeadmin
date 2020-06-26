class RenameViewTypeForCase < ActiveRecord::Migration[4.2]
  def change
    rename_column :cases, :view_type, :case_type
  end
end

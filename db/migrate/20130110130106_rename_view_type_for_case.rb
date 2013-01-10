class RenameViewTypeForCase < ActiveRecord::Migration
  def change
    rename_column :cases, :view_type, :case_type
  end
end

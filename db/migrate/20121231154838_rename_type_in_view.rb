class RenameTypeInView < ActiveRecord::Migration[4.2]
  def change
    rename_column :views, :type, :view_type
  end
end

class RenameTypeInView < ActiveRecord::Migration
  def change
    rename_column :views, :type, :view_type
  end
end

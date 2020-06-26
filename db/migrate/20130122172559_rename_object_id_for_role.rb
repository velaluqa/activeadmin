class RenameObjectIdForRole < ActiveRecord::Migration[4.2]
  def change
    rename_column :roles, :object_id, :subject_id
    rename_column :roles, :object_type, :subject_type
  end
end

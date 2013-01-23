class RenameObjectIdForRole < ActiveRecord::Migration
  def change
    rename_column :roles, :object_id, :subject_id
    rename_column :roles, :object_type, :subject_type
  end
end

class RemoveLegacyRolesColumns < ActiveRecord::Migration
  def change
    Role.destroy_all
    remove_column :roles, :subject_id, :integer, index: true
    remove_column :roles, :subject_type, :string, index: true
    remove_column :roles, :user_id, :integer, index: true
    remove_column :roles, :role, :integer
    add_column :roles, :title, :string, null: false, index: true
  end
end

class ChangeVersionInForms < ActiveRecord::Migration
  def change
    rename_column :forms, :version, :form_version
  end
end

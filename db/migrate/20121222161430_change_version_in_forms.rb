class ChangeVersionInForms < ActiveRecord::Migration[4.2]
  def change
    rename_column :forms, :version, :form_version
  end
end

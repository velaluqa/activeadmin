class RemoveFormVersionFromForms < ActiveRecord::Migration[4.2]
  def up
    remove_column :forms, :form_version
  end

  def down
    add_column :forms, :form_version, :integer
  end
end

class RemoveFormVersionFromForms < ActiveRecord::Migration
  def up
    remove_column :forms, :form_version
  end

  def down
    add_column :forms, :form_version, :integer
  end
end

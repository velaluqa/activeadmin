class RemoveFormIdFromView < ActiveRecord::Migration
  def up
    remove_column :views, :form_id
  end

  def down
    add_column :views, :form_id, :integer
  end
end

class AddStateAndLockedVersionToForms < ActiveRecord::Migration
  def change
    add_column :forms, :state, :integer, default: 0
    add_column :forms, :locked_version, :string
  end
end

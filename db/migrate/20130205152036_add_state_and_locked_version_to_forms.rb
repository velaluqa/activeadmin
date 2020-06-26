class AddStateAndLockedVersionToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :state, :integer, default: 0
    add_column :forms, :locked_version, :string
  end
end

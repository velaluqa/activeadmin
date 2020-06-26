class AddCommentToCases < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :comment, :string
  end
end

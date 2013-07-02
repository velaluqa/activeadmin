class AddCommentToCases < ActiveRecord::Migration
  def change
    add_column :cases, :comment, :string
  end
end

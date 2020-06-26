class AddLockedVersionToStudies < ActiveRecord::Migration[4.2]
  def change
    add_column :studies, :locked_version, :string
  end
end

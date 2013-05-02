class AddLockedVersionToStudies < ActiveRecord::Migration
  def change
    add_column :studies, :locked_version, :string
  end
end

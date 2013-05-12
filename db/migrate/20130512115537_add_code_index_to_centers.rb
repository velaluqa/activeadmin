class AddCodeIndexToCenters < ActiveRecord::Migration
  def change
    add_index(:centers, [:study_id, :code], :unique => true)
  end
end

class AddCodeIndexToCenters < ActiveRecord::Migration
  def change
    add_index(:centers, %i[study_id code], unique: true)
  end
end

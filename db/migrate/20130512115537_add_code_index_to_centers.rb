class AddCodeIndexToCenters < ActiveRecord::Migration[4.2]
  def change
    add_index(:centers, %i[study_id code], unique: true)
  end
end

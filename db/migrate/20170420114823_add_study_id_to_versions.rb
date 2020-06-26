class AddStudyIdToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column(:versions, :study_id, :integer, null: true, index: true)
  end
end

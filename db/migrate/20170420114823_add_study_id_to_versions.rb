class AddStudyIdToVersions < ActiveRecord::Migration
  def change
    add_column(:versions, :study_id, :integer, null: true, index: true)
  end
end

class AddBackgroundJobIdToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :background_job_id, :integer, null: true
  end
end

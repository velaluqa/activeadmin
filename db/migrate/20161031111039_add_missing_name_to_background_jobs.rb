class AddMissingNameToBackgroundJobs < ActiveRecord::Migration
  def up
    add_column :background_jobs, :name, :string, null: true
    BackgroundJob.where(name: nil).each do |job|
      job.name = "BackgroundJob #{job.id}"
      job.save
    end
    change_column :background_jobs, :name, :string, null: false
    add_index :background_jobs, :name
  end

  def down
    remove_column :background_jobs, :name
  end
end

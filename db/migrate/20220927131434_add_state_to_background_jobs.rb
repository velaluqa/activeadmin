class AddStateToBackgroundJobs < ActiveRecord::Migration[5.2]
  def change
    create_enum :background_jobs_state_type, %w[scheduled running cancelling successful failed cancelled]

    add_column :background_jobs, :state, :background_jobs_state_type, null: false, default: "scheduled"

    reversible do |dir|
      dir.up do
        BackgroundJob.skip_callback(:save, :after, :broadcast_job_update)
        BackgroundJob.find_each do |job|
          if job.completed
            if job.successful
              job.state = :successful
            else
              job.state = :failed
            end
          else
            job.state = :running
          end
          job.save
        end
      end
    end
  end
end

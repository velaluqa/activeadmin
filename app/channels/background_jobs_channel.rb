class BackgroundJobsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "background_jobs_channel"

    BackgroundJob.where("updated_at > NOW() - interval '5 second'").each do |job|
      transmit(
        job_id: job.id,
        finished: job.finished?,
        updated_at: job.updated_at,
        html: ApplicationController.new.render_to_string(
          template: "admin/background_jobs/_background_job_state",
          layout: nil,
          locals: {
            background_job: job
          }
        )
      )
    end
  end

  def unsubscribed
    stop_all_streams
  end
end

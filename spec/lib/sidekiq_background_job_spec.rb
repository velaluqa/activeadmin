require 'sidekiq_background_job'

describe SidekiqBackgroundJob do
  let!(:user) { create(:user) }

  before do
    class TestBackgroundJob
      include SidekiqBackgroundJob

      def perform_job(attr)
        set_progress_total!(4)
        increment_progress!
        sleep 1
        if attr == "please_fail"
          throw "Hello, Eric Error!"
        end
        set_progress!(3)
        sleep 1
        increment_progress!
        succeed!({ result: "Hello World, I succeeded!" })
      end
    end
  end

  describe "::perform_async" do
    it 'create a new background job' do
      job = TestBackgroundJob.perform_async(
        "succeed",
        user_id: user.id,
        name: "My very nice background job"
      )
      expect(job).to be_a(BackgroundJob)
      expect(job.scheduled?).to be_truthy
      expect(TestBackgroundJob.jobs).not_to be_empty
    end

    it 'draining it updates the background job state' do
      job = TestBackgroundJob.perform_async(
        "succeed",
        user_id: user.id,
        name: "My very nice background job"
      )

      TestBackgroundJob.drain

      job.reload

      expect(job.successful?).to be_truthy
      expect(TestBackgroundJob.jobs).to be_empty
    end
  end
end

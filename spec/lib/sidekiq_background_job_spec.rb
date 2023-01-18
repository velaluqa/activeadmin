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
        Study.create!(name: "Test Study")
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
    let(:job) {
      TestBackgroundJob.perform_async(
        "succeed",
        name: "My very nice background job"
      )
    }

    it 'create a new background job' do
      expect(job).to be_a(BackgroundJob)
      expect(job.scheduled?).to be_truthy
      expect(TestBackgroundJob.jobs).not_to be_empty
    end

    it 'saves the user id from paper_trail as default' do
      ::PaperTrail.request.whodunnit = "4"

      expect(job.user_id).to eq(4)
    end

    describe "draining the queue" do
      let(:drain_queue) {
        expect(job.scheduled?).to be_truthy
        TestBackgroundJob.drain
        job.reload
      }
      let(:study_version) { Version.where(item_type: "Study").last }

      it 'updates the background job state' do
        drain_queue

        expect(job.successful?).to be_truthy
      end

      it 'saves the background job id to versions created during the job' do
        drain_queue

        expect(study_version.background_job_id).to eq(job.id)
      end

      it 'passes current controller_info of paper_trail' do
        ::PaperTrail.request.controller_info = {
          comment: "This is a comment"
        }

        drain_queue

        expect(study_version.comment).to eq("This is a comment")
      end
    end
  end
end

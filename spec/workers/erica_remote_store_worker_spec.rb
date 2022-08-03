describe ERICARemoteRestoreWorker do
  describe 'failing retries' do
    let(:background_job) { create(:background_job, name: 'Test job') }
      
    it "sets background job status to `failed`" do
      ERICARemoteRestoreWorker.within_sidekiq_retries_exhausted_block({ "args" => [background_job.id] }) do
        expect(ERICARemoteRestoreWorker)
          .to receive(:fail_job_after_exhausting_retries).and_call_original
      end

      background_job.reload

      expect(background_job).to be_failed
    end
  end
end
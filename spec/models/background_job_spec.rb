RSpec.describe BackgroundJob do
  describe 'scope ::searchable' do
    let!(:job) { create(:background_job, name: 'FooJob') }

    it 'selects search fields' do
      expect(BackgroundJob.searchable.as_json)
        .to eq [{
                  'id' => nil,
                  'study_id' => nil,
                  'study_name' => nil,
                  'text' => 'FooJob',
                  'result_id' => job.id,
                  'result_type' => 'BackgroundJob'
                }]
    end
  end

  describe 'scope ::granted_for' do
    it 'returns only the given users background jobs' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user, is_root_user: true)
      job1 = create(:background_job, user_id: user1.id)
      job2 = create(:background_job, user_id: user2.id)
      expect(BackgroundJob.granted_for(user: user1)).to include(job1)
      expect(BackgroundJob.granted_for(user: user1)).not_to include(job2)
      expect(BackgroundJob.granted_for(user: user2)).not_to include(job1)
      expect(BackgroundJob.granted_for(user: user2)).to include(job2)
      expect(BackgroundJob.granted_for(user: user3)).to include(job1, job2)
    end
  end

  describe 'before destroy' do
    it 'removes zip files' do
      background_job = create(:background_job,
                              :complete,
                              :successful,
                              :with_zipfile)
      zipfile = background_job.results['zipfile']
      expect(background_job.results)
        .to eq('zipfile' => 'spec/tmp/background_job_results.zip')
      expect(File).to exist(zipfile)
      background_job.run_callbacks :destroy
      expect(File).not_to exist(zipfile)
    end
  end

  it 'is creatable' do
    job = nil
    expect { job = BackgroundJob.create(name: 'Foo Job') }.not_to raise_error
  end

  describe '#finished?' do
    it 'returns true if complete' do
      job = create(:background_job, :complete)
      expect(job.finished?).to be_truthy
    end

    it 'returns false if not complete' do
      job = create(:background_job)
      expect(job.finished?).to be_falsy
    end
  end

  describe '#failed?' do
    it 'returns false when successful' do
      job = create(:background_job, :complete, :successful)
      expect(job.failed?).to be_falsy
    end

    it 'returns true when failed' do
      job = create(:background_job, :complete, :failed)
      expect(job.failed?).to be_truthy
    end
  end

  describe '#finish_successfully' do
    context 'without results' do
      before(:each) do
        @job = create(:background_job)
        @job.finish_successfully('foo' => 'bar')
        @job = BackgroundJob.find(@job.id)
      end

      it { expect(@job.completed).to be_truthy }
      it { expect(@job.successful).to be_truthy }
      it { expect(@job.completed_at).not_to be_nil }
      it { expect(@job.results).to eq('foo' => 'bar') }
    end

    context 'with results' do
      before(:each) do
        @job = create(:background_job)
        @job.finish_successfully
        @job = BackgroundJob.find(@job.id)
      end

      it { expect(@job.completed).to be_truthy }
      it { expect(@job.successful).to be_truthy }
      it { expect(@job.completed_at).not_to be_nil }
      it { expect(@job.results).to eq({}) }
    end
  end

  describe '#fail' do
    before(:each) do
      @job = create(:background_job)
      @job.fail('Serious error message')
      @job = BackgroundJob.find(@job.id)
    end

    it { expect(@job.completed).to be_truthy }
    it { expect(@job.successful).to be_falsy }
    it { expect(@job.completed_at).not_to be_nil }
    it { expect(@job.error_message).to eq('Serious error message') }
  end

  describe '#set_progress' do
    before(:each) do
      @job = create(:background_job)
      expect(@job.progress).to eq 0.0
      @job.set_progress(50, 100)
      @job = BackgroundJob.find(@job.id)
    end

    it { expect(@job.progress).to eq 0.5 }
  end
end

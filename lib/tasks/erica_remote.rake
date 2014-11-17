namespace :erica do

  desc 'Start an ERICA Remote sync job'
  task :sync_study_to_remote, [:study_id, :remote_url] => [:environment] do |t, args|
    study_id = args[:study_id]
    remote_url = args[:remote_url]
    if(study_id.blank?)
      puts 'No study id given'
      next
    elsif(remote_url.blank?)
      puts 'No remote url given'
      next
    end

    background_job = BackgroundJob.create(:name => "Sync study #{study_id} to #{remote_url}", :user_id => User.where(:username => 'profmaad').first.id)

    ERICARemoteSyncWorker.new.perform(background_job.id.to_s, study_id, remote_url)

    background_job.reload
    pp background_job
  end
end

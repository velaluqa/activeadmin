namespace :erica do

  desc 'Start an ERICA Remote sync job'
  task :sync_study_to_remote, [:study_id, :remote_url, :remote_host] => [:environment] do |t, args|
    study_id = args[:study_id]
    remote_url = args[:remote_url]
    remote_host = args[:remote_host]
    if(study_id.blank?)
      puts 'No study id given'
      next
    elsif(remote_url.blank?)
      puts 'No remote url given'
      next
    end

    background_job = BackgroundJob.create(:name => "Sync study #{study_id} to #{remote_url}", :user_id => User.where(:username => 'rprofmaad').first.id)

    ERICARemoteSyncWorker.new.perform(background_job.id.to_s, study_id, remote_url, remote_host)

    background_job.reload
    pp background_job
  end

  desc 'Download images as zip'
  task :download_images, [:resource_type, :resource_id] => [:environment] do |t, args|
    resource_type = args[:resource_type]
    resource_id = args[:resource_id]

    if(resource_type.blank? or resource_id.blank?)
      puts 'Missing input parameters'
      next
    end

    unless(['Patient', 'Visit'].include?(resource_type))
      puts "Invalid resurce type #{resource_type} given. Valid resource types are: Patient, Visit"
      next_series_number
    end

    background_job = BackgroundJob.create(:name => "Download images for #{resource_type} #{resource_id}", :user_id => User.where(:username => 'rprofmaad').first.id)

    DownloadImagesWorker.new.perform(background_job.id.to_s, resource_type, resource_id)

    background_job.reload

    puts "Download available at #{background_job.results['zipfile']}."
  end
end

namespace :erica do
  namespace :remote do
    desc 'Restore from ERICA remote temp data'
    task :restore, [:export_id] => :environment do |task, args|
      fail 'Only available on ERICA remote installation' unless ERICA.remote?
      export_id = args[:export_id]
      job = BackgroundJob.create(name: "Restore from #{export_id}.tar.lrz")

      if ENV['ASYNC'] =~ /^false|no$/
        ERICARemoteRestoreWorker.new.perform(job.id.to_s, export_id)
      else
        ERICARemoteRestoreWorker.perform_async(job.id.to_s, export_id)
      end
    end

    desc 'Sync to all ERICA remotes (in erica_remotes.yml)'
    task sync_all: :environment do
      fail 'Only available on ERICA store installation' if ERICA.remote?
      require 'remote/remote_sync'
      RemoteSync.perform('config/erica_remotes.yml')
    end
  end

  DEFAULT_CONFIG_FILE = 'config/erica_remotes.yml'

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

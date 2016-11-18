namespace :erica do
  namespace :remote do
    desc 'Restore from ERICA remote temp data'
    task :restore, [:export_id] => :environment do |_, args|
      fail 'Only available on ERICA remote installation' unless ERICA.remote?

      Rake::Task['erica:remote:cleanup'].invoke

      export_id = args[:export_id]

      name = "restore-#{export_id}.tar.lrz"
      job = BackgroundJob.where(name: name, completed: false).first
      fail 'A restore job is already running! Aborting' if job
      job = BackgroundJob.create(name: name)

      if ENV['ASYNC'] =~ /^false|no$/
        ERICARemoteRestoreWorker.new.perform(job.id.to_s, export_id)
      else
        ERICARemoteRestoreWorker.perform_async(job.id.to_s, export_id)
      end
    end

    desc 'Sync datastore and images to all ERICA remotes (in erica_remotes.yml)'
    task sync: ['erica:remote:sync_datastores', 'erica:remote:sync_images']

    desc 'Sync images to all ERICA remotes (in erica_remotes.yml)'
    task :sync_datastores, [:prefix] => :environment do |_, args|
      fail 'Only available on ERICA store installation' if ERICA.remote?

      Rake::Task['erica:remote:cleanup'].invoke

      require 'remote/remote_sync'
      RemoteSync.perform_datastore_sync('config/erica_remotes.yml',
                                        export_id_prefix: args[:prefix])
    end

    desc 'Sync images to all ERICA remotes (in erica_remotes.yml)'
    task sync_images: :environment do
      fail 'Only available on ERICA store installation' if ERICA.remote?
      require 'remote/remote_sync'
      RemoteSync.perform_image_sync('config/erica_remotes.yml')
    end

    task cleanup: :environment do
      puts 'Cleaning up old files ...'
      working_dir = Rails.root.join('tmp', 'remote_sync')
      files = Dir[working_dir.join('*-*-*-*')]

      groups = files.group_by do |e|
        match = e.match(/\d+-\d+-\d+-(.+)$/)
        match[1] if match
      end

      groups.each_pair do |key, files|
        puts "  Deleting old #{key} files ..."
        files.sort[0...-7].each do |file|
          puts "    Deleting #{file}"
          FileUtils.rm_rf(file)
        end
      end
    end

    desc 'Start and keep running the sync process for the day until stopped.'
    task sync_daemon: :environment do
      include Logging
      # The sync is kept running until SIGTERM is received.
      # Unsually that should be done via start-stop-daemon, which also
      # gathers log output and daemonizes the process.
      keep_running = true
      Signal.trap('TERM') do
        logger.info 'Stopping remote synchronization.'
        keep_running = false
        Process.kill 'INT', -Process.getpgrp
        exit 1
      end

      logger.info "Starting remote synchronization supervisor (#{Rails.env})"
      while keep_running
        begin
          yesterday      = Date.yesterday.to_datetime.new_offset(DateTime.now.offset) - DateTime.now.offset
          today          = Date.today.to_datetime.new_offset(DateTime.now.offset) - DateTime.now.offset
          today_noon     = today + 12.hours
          tomorrow       = today + 1.day + 12.hours

          now            = DateTime.now

          prefix =
            if today < now && now <= today_noon
              yesterday.strftime('%Y-%m-%d')
            elsif today_noon < now && now <= tomorrow
              today.strftime('%Y-%m-%d')
            end

          Rake::Task['erica:remote:sync_datastores'].invoke(prefix)
          Rake::Task['erica:remote:sync_images'].invoke
        rescue => e
          puts "Synchronization stopped untimely: #{e}"
          puts e.backtrace
          Airbrake.notify(e)
          if keep_running
            puts 'Retry in 30 seconds'
            sleep 30
          end
        end
      end
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
      puts "Invalid resource type #{resource_type} given. Valid resource types are: Patient, Visit"
      next_series_number
    end

    background_job = BackgroundJob.create(:name => "Download images for #{resource_type} #{resource_id}", :user_id => User.where(:username => 'rprofmaad').first.id)

    DownloadImagesWorker.new.perform(background_job.id.to_s, resource_type, resource_id)

    background_job.reload

    puts "Download available at #{background_job.results['zipfile']}."
  end
end

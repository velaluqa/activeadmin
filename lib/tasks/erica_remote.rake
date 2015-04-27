namespace :erica do

  DEFAULT_CONFIG_FILE = 'config/erica_remotes.yml'

  def get_sync_user_id(config)
    if (config and not config['sync_user_id'].blank?)
      config['sync_user_id']
    elsif User.first
      User.first.id
    else
      1
    end
  end

  def load_sync_config(config_path)
    begin
      config = YAML::load_file(config_path.to_s)
    rescue Errno::ENOENT => e
      puts "Config file at #{config_path.to_s} could not be accessed: #{e.message}"
      return nil
    rescue SyntaxError => e
      puts "Config file is not valid YAML: #{e.message}"
      return nil
    rescue e
      puts "Failed to load config file at #{config_path.to_s}: #{e.message}"
      return nil
    end

    return config
  end

  def sync_study(user_id, study_id, remote_url, remote_host, async = false)
    background_job = BackgroundJob.create(:name => "Sync study #{study_id} to #{remote_url}", :user_id => user_id)

    if(async)
      ERICARemoteSyncWorker.perform_async(background_job.id.to_s, study_id, remote_url, remote_host)
    else
      ERICARemoteSyncWorker.new.perform(background_job.id.to_s, study_id, remote_url, remote_host)
    end

    background_job
  end

  desc 'Start an ERICA Remote sync job'
  task :sync_study_to_remote, [:study_id, :remote_url, :remote_host, :config_file] => [:environment] do |t, args|
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

    config_path = Rails.root.join(args[:config_file] || DEFAULT_CONFIG_FILE)
    config = load_sync_config(config_path)

    sync_user_id = get_sync_user_id(config)

    background_job = sync_study(sync_user_id, study_id, remote_url, remote_host, false)
    background_job.reload
    pp background_job
  end

  desc 'Start a full ERICA Remote sync'
  task :sync_all_erica_remotes, [:config_file] => [:environment] do |t, args|
    time = DateTime.now.strftime('%A, %d %b %Y %l:%M %p')
    puts "Starting full ERICA remote sync (#{time})"

    config_path = Rails.root.join(args[:config_file] || DEFAULT_CONFIG_FILE)

    config = load_sync_config(config_path)
    if(config.nil? or config['remotes'].nil?)
      puts 'No valid config, exiting'
      next
    end

    sync_user_id = get_sync_user_id(config)
    async = config['async'] || false

    config['remotes'].each_with_index do |remote, i|
      study_id = remote['study_id']
      remote_url = remote['remote_url']
      if(study_id.blank?)
        puts "Remote #{i} has no study_id, skipping"
        next
      elsif(remote_url.blank?)
        puts "Remote #{i} has no remote_url, skipping"
        next
      elsif(not Study.exists?(study_id.to_i))
        puts "Remote #{i} study (#{study_id}) doesn't exist, skipping"
        next
      end

      puts "Syncing remote #{i}: #{study_id} -> #{remote_url} #{remote['remote_host'].blank? ? '' : '(@'+remote['remote_host']+')'}"

      background_job = sync_study(sync_user_id, study_id.to_i, remote_url, remote['remote_host'], async)
      background_job.reload unless async

      puts "#{async ? 'STARTED' : 'DONE'}: #{background_job.inspect}"
    end

    time = DateTime.now.strftime('%A, %d %b %Y %l:%M %p')
    puts "Full ERICA remote sync stopped. (#{time})"
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

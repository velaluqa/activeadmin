namespace :erica do
  desc 'Performs a full backup, including RDBMS, MongoDB and data folder'
  task :backup, [:backup_root_folder] => [:environment] do |_t, args|
    backup_root_folder = args[:backup_root_folder]
    if backup_root_folder.blank?
      puts 'No backup root folder given, using /srv/ERICA/backups/'
      backup_root_folder = '/srv/ERICA/backups'
    end

    backup_folder = backup_root_folder + '/' + Time.now.to_s + '/'

    puts "Starting full backup into #{backup_folder}..."
    print "Creating backup directory #{backup_folder}...\t"
    begin
      FileUtils.mkpath(backup_folder)
    rescue => e
      puts 'FAILED: ' + e.message
      next
    end
    puts 'DONE'

    print "Backing up configuration files..\t\t"
    data_tar_command = "tar --exclude=#{Rails.application.config.image_storage_root} --exclude=#{Rails.application.config.image_export_root} -czf \"#{backup_folder}/data.tar.gz\" \"#{Rails.application.config.data_directory}\""
    pp data_tar_command
    if system(data_tar_command)
      puts 'DONE'
    else
      puts 'FAILED'
      next
    end

    puts "Finished full backup into #{backup_folder}"
  end
end

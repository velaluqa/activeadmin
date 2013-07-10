namespace :erica do
  desc 'Performs a full backup, including RDBMS, MongoDB and data folder'
  task :backup, [:backup_root_folder] => [:environment] do |t, args|
    backup_root_folder = args[:backup_root_folder]
    if(backup_root_folder.blank?)
      puts "No backup root folder given, using /srv/ERICA/backups/"
      backup_root_folder = '/srv/ERICA/backups'
    end

    backup_folder = backup_root_folder+'/'+Time.now.to_s+'/'

    puts "Starting full backup into #{backup_folder}..."
    print "Creating backup directory #{backup_folder}...\t"
    begin
      FileUtils.mkpath(backup_folder)
    rescue => e
      puts 'FAILED: '+e.message
      next
    end
    puts 'DONE'

    print "Reading database configs...\t\t"
    sqldb_config = Rails.application.config.database_configuration[Rails.env]
    mongodb_config = Rails.application.config.mongoid.sessions['default']
    if(sqldb_config.nil? or mongodb_config.nil?)
      puts 'FAILED'
      next
    end
    puts 'DONE'
    
    print "Backing up SQL database...\t\t"
    sql_dump_command = case sqldb_config['adapter']
                       when 'sqlite3', 'sqlite'
                         "cp \"#{sqldb_config['database']}\" \"#{backup_folder}\""
                       when 'postgresql'
                         username_option = sqldb_config['username'].blank? ? '' : ' -U'+sqldb_config['username']
                         host_option = sqldb_config['host'].blank? ? '' : ' -h'+sqldb_config['host']              
                         output_file = backup_folder + sqldb_config['database']+'.sql'

                         'pg_dump ' +username_option +host_option +' '+sqldb_config['database'] +' > "'+output_file+'"'
                       else
                         nil
                       end
    if(sql_dump_command.nil?)
      puts "FAILED: unsupported database adapter #{sqldb_config['adapter']}"
      next
    end

    pp sql_dump_command
    if(system(sql_dump_command))
      puts 'DONE'
    else
      puts 'FAILED'
      next
    end

    print "Backing up MongoDB database..\t\t"
    mongodump_command = "mongodump --host #{mongodb_config['hosts'].first} --db #{mongodb_config['database']} --out \"#{backup_folder}/mongodb\""
    pp mongodump_command
    if(system(mongodump_command))
      puts 'DONE'
    else
      puts 'FAILED'
      next
    end
    
    print "Backing up configuration files..\t\t"
    data_tar_command = "tar --exclude=#{Rails.application.config.image_storage_root} --exclude=#{Rails.application.config.image_export_root} -czf \"#{backup_folder}/data.tar.gz\" \"#{Rails.application.config.data_directory}\""
    pp data_tar_command
    if(system(data_tar_command))
      puts 'DONE'
    else
      puts 'FAILED'
      next
    end

    puts "Finished full backup into #{backup_folder}"
  end
end

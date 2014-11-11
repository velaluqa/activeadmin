namespace :erica do

  # to be archived:
  # - MongoDB:
  #   - ImageSeriesData
  #   - VisitData
  #   - PatientData
  #   - MongoidHistoryTrackers for the above
  # - RDBMS:
  #   - Study
  #   - Centers
  #   - Patients
  #   - ImageSeries
  #   - Images
  #   - Visits
  #   - Versions for the above
  #   - Users, PublicKeys
  # - Config files (incl. git)
  # - Image Storage

  # Export procedure for PostgreSQL:
  # 1. create new database to hold archive
  # 2. create table schema in archive db (CREATE TABLE .. LIKE .. INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES)
  # 3. copy data (INSERT INTO .. SELECT, same as sqlite)
  # 4. pg_dump archive db
  # 5. drop archive db

  SQL_TABLES_TO_ARCHIVE = ['users', 'public_keys', 'studies', 'centers', 'patients', 'visits', 'image_series', 'images', 'versions']

  def system_or_die(command)
    unless(system(command))
      raise 'Failed to execute shell command: "' + command + "\"\nWARNING: THE ARCHIVE IS INCOMPLETE!"
    end
  end
  def rsync_or_die(command)
    sync_command = 'rsync -av ' + command
    verify_command = 'rsync -a --stats -n ' + command

    puts 'RSYNC: ' + sync_command
    system_or_die(sync_command)

    puts 'RSYNC VERIFY: ' + verify_command
    rsync_output = %x{#{verify_command}}

    unsynced_file_count = 0
    rsync_output.lines.each do |line|
      puts line
      if line =~ /^Number of created files: ([0-9]+)/
        unsynced_file_count += $1.to_i
        puts unsynced_file_count
      elsif line =~ /^Number of deleted files: ([0-9]+)/
        unsynced_file_count += $1.to_i
        puts unsynced_file_count
      elsif line =~ /^Number of regular files transferred: ([0-9]+)/
        unsynced_file_count += $1.to_i
        puts unsynced_file_count
      end
    end

    if(unsynced_file_count > 0)
      raise "Failed to rsync image storage, #{unsynced_file_count} files remain unsynced.\nWARNING: THE ARCHIVE IS INCOMPLETE!"
    end
  end

  def postgresql_create_database(name)
    ActiveRecord::Base.connection.execute("CREATE SCHEMA #{name};")
  end
  def postgresql_drop_database(name)
    ActiveRecord::Base.connection.execute("DROP SCHEMA #{name} CASCADE;")
  end
  def postgresql_create_table_like(source, target_db)
    create_table_sql = "CREATE TABLE #{target_db}.\"#{source}\" (LIKE \"#{source}\" INCLUDING ALL);"
    puts 'EXECUTING: ' + create_table_sql
    ActiveRecord::Base.connection.execute(create_table_sql)
  end
  def postgresql_dump_database(rails_db_name, db_name, archive_dump_pathname)
    dump_command = "pg_dump -Ox -n '#{db_name}' '#{rails_db_name}' | gzip -9 > '#{archive_dump_pathname.to_s}'"

    puts 'EXECUTING: ' + dump_command
    system_or_die(dump_command)
  end

  def sqlite3_create_table_like(source, target_db)
    create_table_sql = ActiveRecord::Base.connection.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name='#{source}';").first['sql']
    index_sqls = ActiveRecord::Base.connection.execute("SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='#{source}';").map {|e| e['sql']}

    create_target_table_sql = create_table_sql.gsub(Regexp.new("CREATE TABLE \"#{source}\""), "CREATE TABLE #{target_db}.\"#{source}\"")
    target_index_sqls = index_sqls.map {|sql| sql.gsub(Regexp.new("INDEX \""), "INDEX #{target_db}.\"")}
    puts create_target_table_sql
    puts target_index_sqls
    ActiveRecord::Base.connection.execute(create_target_table_sql)
    target_index_sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def sql_insert_select(target_db, target_table, query)
    sql = "INSERT INTO #{target_db}.\"#{target_table}\" #{query};"
    puts sql
    ActiveRecord::Base.connection.execute(sql)
  end
  def sql_archive(archive_db_name, study)
    sql_insert_select(archive_db_name, 'users', "SELECT * FROM users")
    sql_insert_select(archive_db_name, 'public_keys', "SELECT * FROM public_keys")

    sql_insert_select(archive_db_name, 'studies', "SELECT * FROM studies WHERE id = #{study.id}")

    sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Study' AND item_id = #{study.id}")

    sql_insert_select(archive_db_name, 'centers', "SELECT * FROM centers WHERE study_id = #{study.id}")
    study.centers.each do |center|
      sql_insert_select(archive_db_name, 'patients', "SELECT * FROM patients WHERE center_id = #{center.id}")

      sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Center' AND item_id = #{center.id}")

      center.patients.each do |patient|
        sql_insert_select(archive_db_name, 'image_series', "SELECT * FROM image_series WHERE patient_id = #{patient.id}")
        sql_insert_select(archive_db_name, 'visits', "SELECT * FROM visits WHERE patient_id = #{patient.id}")

        sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Patient' AND item_id = #{patient.id}")

        patient.image_series.each do |is|
          sql_insert_select(archive_db_name, 'images', "SELECT * FROM images WHERE image_series_id = #{is.id}")

          sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'ImageSeries' AND item_id = #{is.id}")

          is.images.each do |image|
            sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Image' AND item_id = #{image.id}")
          end
        end

        patient.visits.each do |visit|
          sql_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Visit' AND item_id = #{visit.id}")
        end
      end
    end
  end

  def sqlite3_archive(archive_db_pathname, archive_db_name, study)
    ActiveRecord::Base.connection.execute("ATTACH DATABASE '#{archive_db_pathname.to_s}' AS #{archive_db_name};")

    SQL_TABLES_TO_ARCHIVE.each do |table|
      sqlite3_create_table_like(table, archive_db_name)
    end

    sql_archive(archive_db_name, study)

    ActiveRecord::Base.connection.execute("DETACH DATABASE #{archive_db_name};")
  end
  def postgresql_archive(archive_dump_pathname, archive_db_name, study)
    postgresql_create_database(archive_db_name)

    SQL_TABLES_TO_ARCHIVE.each do |table|
      postgresql_create_table_like(table, archive_db_name)
    end

    sql_archive(archive_db_name, study)

    postgresql_dump_database(Rails.configuration.database_configuration[Rails.env]['database'], archive_db_name, archive_dump_pathname)

    postgresql_drop_database(archive_db_name)
  end

  def mongodb_export(host, collection, query, outfile)
    mongoexport_call = "mongoexport #{host} --collection #{collection} --query '#{query}' >> '#{outfile}'"

    puts 'EXECUTING: ' + mongoexport_call
    system_or_die(mongoexport_call)
  end
  def mongodb_export_documents(collection, id_field, ids, outfile, host)
    ids_string = '[' + ids.map {|id| id.to_s}.join(', ') + ']'
    document_query = "{#{id_field}: { $in: #{ids_string} } }"
    puts document_query

    mongodb_export(host, collection, document_query, outfile)
  end
  
  desc 'Archive a study and all its contents, removing them from ERICAv2.'
  task :archive_study, [:study_id, :archive_path] => [:environment] do |t, args|
    mongodb_server = Mongoid.configure.sessions[:default]
    mongoexport_host_string = "--db #{mongodb_server[:database]} --host #{mongodb_server[:hosts].first}"

    study_id = args[:study_id]
    archive_path = args[:archive_path]
    if(study_id.blank?)
      puts 'No study id given'
      next
    elsif(archive_path.blank?)
      puts 'No archive destination path given'
      next
    end

    unless(['PostgreSQL', 'SQLite'].include?(ActiveRecord::Base.connection.adapter_name))
      raise "Unhandled RDBMS adapter: #{ActiveRecord::Base.connection.adapter_name}. This script only supports PostgreSQL and SQLite!"
    end

    print "Search study with id #{study_id}..."
    study = Study.where(id: study_id.to_i).first
    if study.nil?
      puts 'NOT FOUND'
      next
    else
      puts "FOUND: #{study.inspect}"
    end

    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    puts "WARNING: THIS WILL ARCHIVE ALL DATA FOR STUDY '#{study.name}', INCLUDING DATABASE ENTRIES, AUDIT TRAIL ENTRIES, IMAGES AND CONFIGURATION."
    puts "WARNING: THE DATA WILL BE DELETED FROM THE PRODUCTION DATABASE. THIS PROCESS IS NOT EASILY REVERSIBLE!"
    puts "WARNING: TO CONFIRM THAT YOU WANT TO START THIS PROCESS, PLEASE RECONFIRM THE STUDY NAME BELOW, EXACTLY AS IT APPEARS ABOVE."
    print "WARNING: STUDY NAME> "
    study_name_confirmation = STDIN.gets.chomp("\n")
    if(study_name_confirmation != study.name)
      puts "PROCESS ABORTED!"
      next
    end

    archive_pathname = Pathname.new(archive_path)
    if(archive_pathname.file?)
      puts 'The given archive path is a file, please specify a directory'
      next
    elsif(not archive_pathname.exist?)
      begin
        archive_pathname.mkdir
      rescue SystemCallError => e
        puts "Failed to create directory at the given archive destination path: #{e.message}"
        next
      end
    end

    puts "Archiving image storage"
    image_archive_pathname = archive_pathname.join('image_storage')
    image_archive_pathname.mkdir
    study_image_storage_path = study.absolute_image_storage_path
    study_image_storage_path.chomp!('/')

    image_archive_path_string = image_archive_pathname.to_s
    image_archive_path_string += '/' unless image_archive_path_string.end_with?('/')

    rsync_or_die(study_image_storage_path + ' ' + image_archive_path_string)

    puts "Archiving configuration files"
    data_archive_pathname = archive_pathname.join('data.tar.gz')
    data_tar_command = "tar --exclude=#{Rails.application.config.image_storage_root} --exclude=#{Rails.application.config.image_export_root} -c \"#{Rails.application.config.data_directory}\" | gzip -9 > \"#{data_archive_pathname.to_s}\""
    puts 'EXECUTING: ' + data_tar_command
    system_or_die(data_tar_command)

    puts "Archiving MongoDB documents"
    archive_mongodb_pathname = archive_pathname.join('mongodb')
    archive_mongodb_pathname.mkdir

    mongoid_history_trackers_pathname = archive_mongodb_pathname.join('mongoid_history_tracker.json')
    [
      {name: 'VisitData', data_ids: study.visits.map {|v| v.visit_data.nil? ? nil : v.visit_data.id}},
      {name: 'PatientData', data_ids: study.patients.map {|p| p.patient_data.nil? ? nil : p.patient_data.id}},
      {name: 'ImageSeriesData', data_ids: study.image_series.map {|is| is.image_series_data.nil? ? nil : is.image_series_data.id}},
    ].each do |spec|
      spec[:data_ids].each do |id|
        next if id.nil?

        query = "{ association_chain: { $elemMatch: { name: \"#{spec[:name]}\", id: ObjectId(\"#{id}\") }}}"
        mongodb_export(mongoexport_host_string, 'mongoid_history_trackers', query, mongoid_history_trackers_pathname.to_s)
      end
    end

    [
      {collection: 'visit_data', id_field: 'visit_id', ids: study.visits.map{|v| v.id}},
      {collection: 'image_series_data', id_field: 'image_series_id', ids: study.image_series.map{|is| is.id}},
      {collection: 'patient_data', id_field: 'patient_id', ids: study.patients.map{|p| p.id}}
    ].each do |export_spec|
      outfile_pathname = archive_mongodb_pathname.join(export_spec[:collection] + '.json')
      mongodb_export_documents(export_spec[:collection], export_spec[:id_field], export_spec[:ids], outfile_pathname.to_s, mongoexport_host_string)
    end


    case ActiveRecord::Base.connection.adapter_name
    when 'PostgreSQL'
      archive_db_name = 'archive_db_' + Time.now.strftime('%Y%m%d%H%M%S')
      archive_postgresql_dump_pathname = archive_pathname.join('database.sql.gz')

      postgresql_archive(archive_postgresql_dump_pathname, archive_db_name, study)

      puts "Created archive SQL dump at #{archive_postgresql_dump_pathname.to_s}"
    when 'SQLite'
      archive_db_name = 'archive_db'
      archive_sqlite3_db_pathname = archive_pathname.join('database.sqlite3')

      sqlite3_archive(archive_sqlite3_db_pathname, archive_db_name, study)

      puts "Created archive db at #{archive_sqlite3_db_pathname.to_s}"
    else
      raise "Unhandled RDBMS adapter: #{ActiveRecord::Base.connection.adapter_name}. This script only supports PostgreSQL and SQLite!"
    end

    print 'Finished creating archive, removing study from ERICAv2 now...'
    result = true
    PaperTrail.enabled = false
    Mongoid::History.disable do
      result = ActiveRecord::Base.transaction do

        study.image_series.each do |image_series|
          image_series.images.each do |image|
            Version.where('item_type = \'Image\' AND item_id = ?', image.id).delete_all
          end

          Version.where('item_type = \'ImageSeries\' AND item_id = ?', image_series.id).delete_all
          image_series.image_series_data.history_tracks.delete_all if(image_series.image_series_data)
        end

        study.visits.each do |visit|
          Version.where('item_type = \'Visit\' AND item_id = ?', visit.id).delete_all
          visit.visit_data.history_tracks.delete_all if(visit.visit_data)
        end

        study.patients.each do |patient|
          Version.where('item_type = \'Patient\' AND item_id = ?', patient.id).delete_all
          patient.patient_data.history_tracks.delete_all if(patient.patient_data)
          patient.destroy
        end

        study.reload
        study.centers.each do |center|
          center.reload
          Version.where('item_type = \'Center\' AND item_id = ?', center.id).delete_all
          center.destroy
        end

        study.reload
        Version.where('item_type = \'Study\' AND item_id = ?', study.id).delete_all
        study.destroy

      end
    end
    PaperTrail.enabled = true

    if(result == false)
      puts 'FAILED: some records might not have been deleted'
    else
      puts 'DONE'
    end
  end
end

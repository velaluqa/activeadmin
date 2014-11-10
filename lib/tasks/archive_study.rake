namespace :erica do

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
  def sqlite3_insert_select(target_db, target_table, query)
    sql = "INSERT INTO #{target_db}.\"#{target_table}\" #{query};"
    puts sql
    ActiveRecord::Base.connection.execute(sql)
  end
  def sqlite3_archive(archive_db_pathname, archive_db_name, study)
    ActiveRecord::Base.connection.execute("ATTACH DATABASE '#{archive_db_pathname.to_s}' AS #{archive_db_name};")

    ['users', 'public_keys', 'studies', 'centers', 'patients', 'visits', 'image_series', 'images', 'versions'].each do |table|
      sqlite3_create_table_like(table, archive_db_name)
    end

    sqlite3_insert_select(archive_db_name, 'users', "SELECT * FROM users")
    sqlite3_insert_select(archive_db_name, 'public_keys', "SELECT * FROM public_keys")

    sqlite3_insert_select(archive_db_name, 'studies', "SELECT * FROM studies WHERE id = #{study.id}")

    sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Study' AND item_id = #{study.id}")

    sqlite3_insert_select(archive_db_name, 'centers', "SELECT * FROM centers WHERE study_id = #{study.id}")
    study.centers.each do |center|
      sqlite3_insert_select(archive_db_name, 'patients', "SELECT * FROM patients WHERE center_id = #{center.id}")

      sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Center' AND item_id = #{center.id}")

      center.patients.each do |patient|
        sqlite3_insert_select(archive_db_name, 'image_series', "SELECT * FROM image_series WHERE patient_id = #{patient.id}")
        sqlite3_insert_select(archive_db_name, 'visits', "SELECT * FROM visits WHERE patient_id = #{patient.id}")

        sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Patient' AND item_id = #{patient.id}")

        patient.image_series.each do |is|
          sqlite3_insert_select(archive_db_name, 'images', "SELECT * FROM images WHERE image_series_id = #{is.id}")

          sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'ImageSeries' AND item_id = #{is.id}")

          is.images.each do |image|
            sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Image' AND item_id = #{image.id}")
          end
        end

        patient.visits.each do |visit|
          sqlite3_insert_select(archive_db_name, 'versions', "SELECT * FROM versions WHERE item_type = 'Visit' AND item_id = #{visit.id}")
        end
      end
    end

    ActiveRecord::Base.connection.execute("DETACH DATABASE #{archive_db_name};")
  end
  def mongodb_export(host, collection, query, outfile)
    mongoexport_call = "mongoexport #{host} --collection #{collection} --query '#{query}' >> '#{outfile}'"

    puts 'EXECUTING: ' + mongoexport_call
    system(mongoexport_call)
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

    print "Search study with id #{study_id}..."
    study = Study.where(id: study_id.to_i).first
    if study.nil?
      puts 'NOT FOUND'
      next      
    else
      puts "FOUND: #{study.inspect}"
    end

    puts "Exporting MongoDB documents"
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

    next

    archive_sqlite3_db_pathname = archive_pathname.join('database.sqlite3')
    archive_db_name = 'archive_db'

    sqlite3_archive(archive_sqlite3_db_pathname, archive_db_name, study)

    puts "Created archive db at #{archive_sqlite3_db_pathname.to_s}"
  end
end

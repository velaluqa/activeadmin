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

    ['studies', 'centers', 'patients', 'visits', 'image_series', 'images', 'versions'].each do |table|
      sqlite3_create_table_like(table, archive_db_name)
    end

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
  
  desc 'Archive a study and all its contents, removing them from ERICAv2.'
  task :archive_study, [:study_id, :archive_path] => [:environment] do |t, args|
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

    archive_sqlite3_db_pathname = archive_pathname.join('database.sqlite3')
    archive_db_name = 'archive_db'

    sqlite3_archive(archive_sqlite3_db_pathname, archive_db_name, study)

    puts "Created archive db at #{archive_sqlite3_db_pathname.to_s}"
  end
end

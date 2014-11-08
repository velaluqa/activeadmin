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

    # WARNING: SQLite specific code, only for development/testing
    sqlite_db_pathname = archive_pathname.join('database.sqlite3')
    archive_db_name = 'archive_db'
    ActiveRecord::Base.connection.execute("ATTACH DATABASE '#{sqlite_db_pathname.to_s}' AS #{archive_db_name};")

    ['studies', 'centers', 'patients', 'visits', 'image_series', 'images', 'versions'].each do |table|
      sqlite3_create_table_like(table, archive_db_name)
    end

    ActiveRecord::Base.connection.execute("DETACH DATABASE archive_db;")
    puts "Created archive db at #{sqlite_db_pathname.to_s}"
  end
end

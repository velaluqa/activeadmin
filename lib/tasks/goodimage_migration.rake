begin
  require 'goodimage_migration/initialize'
  require 'goodimage_migration/migrator'

  namespace :goodimage_migration do
    desc "Initialize the migration environment (without initializing the Rails environment)"
    task :base_initialize do
      PaperTrail.enabled = false
      GoodImageMigration.initialize
      puts "Migration environment initialized."
    end
    desc "Initialize the migration environment"
    task :initialize => [:environment, :base_initialize]

    task :setup_migration_db => :base_initialize do
      GoodImageMigration.setup_migration_db
    end
    task :clear_migration_db => :base_initialize do
      GoodImageMigration.clear_migration_db
    end

    desc "Open an IRB instance in the GoodImage DB context"
    task :goodimage_irb => [:initialize] do
      puts "Working in GoodImage context!"

      argv = ARGV
      ARGV.replace([])

      IRB.start

      ARGV.replace(argv)
    end

    desc "Migrate the GoodImage study with the specified ID to ERICA"
    task :migrate_study, [:goodimage_study_id] => [:initialize] do |t, args|
      if(args[:goodimage_study_id].nil?)
        puts "No GoodImage study id given, not migrating."
        next
      end
      goodimage_study_id = args[:goodimage_study_id]

      config = GoodImageMigration.migration_config
      if(config.nil? or config['goodimage_image_storage'].nil?)
        puts "No valid config containing 'goodimage_image_storage' found, aborting."
        next
      end

      puts "Attempting migration for GoodImage study with ID = #{goodimage_study_id}"
      goodimage_study = GoodImageMigration::GoodImage::Study.get(goodimage_study_id)
      if(goodimage_study.nil?)
        puts "Could not find the study in GoodImage, aborting!"
      else
        puts "Found the study in GoodImage, starting migration..."
        migrator = GoodImageMigration::Migrator.new(config)
        start_time = Time.now
        if(migrator.migrate(goodimage_study, nil))
          puts "Migration successful!"
        else
          puts "Migration failed, please consult the log for details."
        end
        end_time = Time.now
        puts "Migration started at #{start_time.inspect}"
        puts "Migration ended at #{end_time.inspect}"
        puts "Migration took #{end_time - start_time} seconds"
      end
    end

    desc "Migrate all GoodImage studies to ERICA"
    task :migrate => [:initialize] do
      config = GoodImageMigration.migration_config
      if(config.nil? or config['goodimage_image_storage'].nil?)
        puts "No valid config containing 'goodimage_image_storage' found, aborting."
        next
      end

      puts "Attempting migration for all GoodImage studies"
      goodimage_studies = GoodImageMigration::GoodImage::Study.all

      puts "Found #{goodimage_studies.count} studies in GoodImage, starting migration..."
      migrator = GoodImageMigration::Migrator.new(config, goodimage_studies.count)
      start_time = Time.now

      success = true
      goodimage_studies.each do |goodimage_study|
        unless(migrator.migrate(goodimage_study, nil))
          success = false
          break
        end
      end

      if(success)
        puts "Migration successful!"
      else
        puts "Migration failed, please consult the log for details."
      end

      end_time = Time.now
      puts "Migration started at #{start_time.inspect}"
      puts "Migration ended at #{end_time.inspect}"
      puts "Migration took #{end_time - start_time} seconds"
    end

    desc "Copy all missing images from GoodImage to the ERICA image storage"
    task :copy_missing_images => [:initialize] do
      config = GoodImageMigration.migration_config
      if(config.nil? or config['goodimage_image_storage'].nil?)
        puts "No valid config containing 'goodimage_image_storage' found, aborting."
        next
      end

      migrator = GoodImageMigration::Migrator.new(config, 0)
      start_time = Time.now

      migrator.copy_missing_images

      end_time = Time.now
      puts "Migration started at #{start_time.inspect}"
      puts "Migration ended at #{end_time.inspect}"
      puts "Migration took #{end_time - start_time} seconds"
    end

    desc 'Generate a migration report for the given GoodImage study, based on a past migration (info in migration mapping db)'
    task :migration_report, [:goodimage_study_id, :report_path] => [:initialize] do |t, args|
      if(args[:goodimage_study_id].blank?)
        puts 'No GoodImage study id given, aborting...'
        next
      end
      goodimage_study_id = args[:goodimage_study_id]

      if(args[:report_path].blank?)
        puts 'No path for report given, aborting...'
        next
      end
      report_path = args[:report_path]

      config = GoodImageMigration.migration_config
      if(config.nil? or config['goodimage_image_storage'].nil?)
        puts "No valid config containing 'goodimage_image_storage' found, aborting..."
        next
      end

      puts 'Fetching GoodImage study with id '+goodimage_study_id.to_s+'...'
      goodimage_study = GoodImageMigration::GoodImage::Study.get(goodimage_study_id)
      if(goodimage_study.nil?)
        puts 'Could not find the study in GoodImage, aborting...'
        next
      else
        puts 'Found the study in GoodImage, generating report...'
      end

      migrator = GoodImageMigration::Migrator.new(config, 0)
      start_time = Time.now

      migrator.migration_report(goodimage_study, report_path)

      end_time = Time.now
      puts "Process started at #{start_time.inspect}"
      puts "Process ended at #{end_time.inspect}"
      puts "Process took #{end_time - start_time} seconds"
    end
  end
rescue LoadError => e
  # puts "GoodImage migration not available because of missing dependencies: #{e.message}"
end

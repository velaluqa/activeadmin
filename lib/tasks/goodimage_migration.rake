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

  task :image_path_test => [:initialize] do
    images_index = {}
    File.open('/home/profmaad/Workspace/freelance/PharmTrace/GoodImage Migration/Documentation/goodimage_file_listing.txt', 'r') do |f|
      f.each_line do |line|
        line.strip!
        images_index[line[2..-1]] = true if line.end_with?('.dcm')
      end
    end
    puts "Indexed #{images_index.size} file names"

    total_images_count = GoodImageMigration::GoodImage::Image.count
    puts "Checking whether all #{total_images_count} files are present and accounted for..."
    offenders = []
    count = 2440000
    while(count < total_images_count)
      GoodImageMigration::GoodImage::Image.all(:limit => 10000, :offset => count).each do |image|
        if(images_index[image.file_path].nil? and image.study_internal_id != '340044')
          offenders << image
          break if offenders.size > 23
        end        

        count += 1
      end
      print '.'
      puts "\n#{count}" if(count % 100000 == 0)
      break if offenders.size > 23
    end
    puts "Result: #{offenders.empty?}"
    unless(offenders.empty?)
      puts "Offenders:"
      GoodImageMigration.pp_array offenders
    end
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
      puts "Migration took: #{end_time - start_time}"
    end
  end
end

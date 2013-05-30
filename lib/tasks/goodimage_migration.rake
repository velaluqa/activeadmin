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

    puts "Attempting migration for GoodImage study with ID = #{goodimage_study_id}"
    goodimage_study = GoodImageMigration::GoodImage::Study.get(goodimage_study_id)
    if(goodimage_study.nil?)
      puts "Could not find the study in GoodImage, aborting!"
    else
      puts "Found the study in GoodImage, starting migration..."
      migrator = GoodImageMigration::Migrator.new
      if(migrator.migrate(goodimage_study, nil))
        puts "Migration successful!"
      else
        puts "Migration failed, please consult the log for details."
      end
    end
  end
end

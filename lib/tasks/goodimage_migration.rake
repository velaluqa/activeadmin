require 'goodimage_migration/initialize'

namespace :goodimage_migration do  
  desc "Initialize the migration environment (without initializing the Rails environment)"
  task :base_initialize do
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
end

require 'goodimage_migration/initialize'

namespace :goodimage_migration do  
  desc "Initialize the migration environment"
  task :initialize => :environment do
    GoodImageMigration.initialize
    puts "Migration environment initialized."
  end
 
  desc "Open an IRB instance in the GoodImage DB context"
  task :goodimage_irb => [:initialize] do
    puts "Working in GoodImage context!"
    argv = ARGV
    ARGV.replace([])
    DataMapper.repository(:goodimage) do
      IRB.start
    end
    ARGV.replace(argv)
  end
end

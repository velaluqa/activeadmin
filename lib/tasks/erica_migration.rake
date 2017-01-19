namespace :erica do
  namespace :migration do
    Dir['./lib/migration/*'].each do |path|
      name = File.basename(path, '.*')

      desc "Runs migration from #{path}"
      task name.to_sym => :environment do
        require path
        migration_class = "Migration::#{name.camelize}".constantize
        migration_class.run
      end
    end
  end
end

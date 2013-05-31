require 'yaml'
require 'data_mapper'
require 'pp'

require 'goodimage_migration/models'

module GoodImageMigration
  def self.migration_config
    environment = ENV['MIGRATION_ENV'] || Rails.env
    config = YAML::load_file('config/goodimage_migration.yml')

    if(config.nil?)
      puts "No valid migration config found in config/goodimage_migration.yml, exiting."
      return nil
    elsif(config[environment].nil?)
      puts "Running in environment #{environment}, but no such environment is defined in the migration config, exiting."
      return nil
    end

    return config[environment]
  end

  def self.initialize
    DataMapper::Logger.new($stdout, :info)

    config = self.migration_config
    if(config['migration_db'].nil? or config['goodimage_db'].nil?)
      puts "Running in environment #{environment}, but not all required databases (migration_db, goodimage_db) are defined in the config, exiting."
      return false
    end

    DataMapper.setup(:default, config['migration_db'])
    DataMapper.setup(:goodimage, config['goodimage_db'])

    DataMapper.finalize
    return true
  end

  def self.setup_migration_db
    GoodImageMigration::Migration::Mapping.auto_upgrade!
  end
  def self.clear_migration_db
    GoodImageMigration::Migration::Mapping.auto_migrate!
  end

  def self.pp_array(a)
    a.each do |e|
      pp e
    end

    return a.size
  end
end

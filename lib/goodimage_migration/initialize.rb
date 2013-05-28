require 'yaml'
require 'data_mapper'
require 'pp'

require 'goodimage_migration/models'

module GoodImageMigration
  def self.initialize
    environment = ENV['MIGRATION_ENV'] || Rails.env

    DataMapper::Logger.new($stdout, :debug)

    config = YAML::load_file('config/goodimage_migration.yml')
    if(config.nil?)
      puts "No valid migration config found in config/goodimage_migration.yml, exiting."
      return false
    elsif(config[environment].nil?)
      puts "Running in environment #{environment}, but no such environment is defined in the migration config, exiting."
      return false
    elsif(config[environment]['migration_db'].nil? or config[environment]['goodimage_db'].nil?)
      puts "Running in environment #{environment}, but not all required databases (migration_db, goodimage_db) are defined in the config, exiting."
      return false
    end
    config = config[environment]

    DataMapper.setup(:default, config['migration_db'])
    DataMapper.setup(:goodimage, config['goodimage_db'])

    DataMapper.finalize
    return true
  end

  def self.pp_array(a)
    a.each do |e|
      pp e
    end

    return a.size
  end
end

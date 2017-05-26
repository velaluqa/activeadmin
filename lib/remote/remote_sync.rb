require 'remote/remote'
require 'remote/datastore_sync'
require 'remote/image_sync'

class RemoteSync
  include Logging

  attr_reader :config, :remotes

  def initialize(config_file)
    @config = load_configuration(config_file)
    @remotes = config.delete('remotes').map { |conf| Remote.new(conf) }

    dups = remotes.map(&:name).select { |e| remotes.count(e) > 1 }.uniq
    raise "Duplicate remote names found: #{dups}" unless dups.empty?
  end

  def perform_datastore_sync(options = {})
    remotes.each { |remote| Remote::DatastoreSync.perform(remote, options) }
  end

  def perform_image_sync
    remotes.each { |remote| Remote::ImageSync.perform(remote) }
  end

  class << self
    def perform_datastore_sync(config_file, options = {})
      RemoteSync.new(config_file).perform_datastore_sync(options)
    end

    def perform_image_sync(config_file)
      RemoteSync.new(config_file).perform_image_sync
    end
  end

  private

  def load_configuration(filename)
    YAML.load_file(filename)
  rescue Errno::ENOENT => e
    logger.error "Config file at #{filename} could not be accessed: #{e.message}"
  rescue SyntaxError
    logger.error "Config file is not valid YAML: #{filename}"
  rescue e
    logger.error "Failed to load config file at #{filename}: #{e.message}"
  end
end

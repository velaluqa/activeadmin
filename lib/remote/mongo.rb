require 'remote/mongo/dumper'
require 'remote/mongo/restore'

class Mongo
  class << self
    include Logging

    def dump(options = {})
      options = { out: Rails.root.join('tmp', 'remote_sync') }.merge(options)
      logger.info("dumping mongo collections into #{options[:out]}")
      Mongo::Dumper.dump(options)
    end
  end
end

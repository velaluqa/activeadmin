require 'remote/sql/dumper'
require 'remote/sql/restore'

class Sql
  class << self
    include Logging

    def dump_upserts(filename, options = {})
      logger.info("dumping #{yield.count} record(s) into #{Pathname.new(filename).relative_path_from(Rails.root)}")
      dumper = Sql::Dumper.new(yield, options)
      File.open(filename, 'w+') { |io| dumper.dump_upserts(io) }
    end
  end
end

require 'remote/sql/restore'
require 'remote/mongo/restore'

class RemoteRestore
  attr_reader :export_id

  def initialize(export_id)
    @export_id = export_id
  end

  def log(message)
    puts "#{DateTime.now} - #{message}"
  end

  def extract_archive!
    log("extracting #{export_id}.tar.lrz")
    system("cd #{Rails.root.join('tmp')}; lrzuntar #{export_id}.tar.lrz")
  end

  def restore_sql(filename)
    log("restoring sql file #{export_id}/#{filename}")
    remote_tmp = Rails.root.join('tmp', export_id)
    Sql::Restore.from_file(remote_tmp.join(filename))
  end

  def restore_mongo(dir = 'mongo_dump')
    log("restoring mongodump from #{export_id}/#{dir}")
    Mongo::Restore.from_dir(Rails.root.join('tmp', export_id, dir))
  end
end

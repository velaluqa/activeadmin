require 'remote/sql/restore'
require 'remote/mongo/restore'

class RemoteRestore
  include Logging

  attr_reader :export_id, :working_dir, :archive_file, :export_dir

  def initialize(export_id)
    @export_id = export_id
    @working_dir = Rails.root.join('tmp', 'remote_sync')
    @archive_file = working_dir.join("#{export_id}.tar.lrz")
    @export_dir = working_dir.join(export_id)
  end

  def extract_archive!
    logger.info("extracting #{archive_file.relative_path_from(Rails.root)}")
    system("cd #{Shellwords.escape(working_dir.to_s)}; lrzuntar #{Shellwords.escape(archive_file.to_s)}")
  end

  def restore_sql(filename)
    logger.info("restoring sql file #{export_dir.join(filename).relative_path_from(Rails.root)}")
    Sql::Restore.from_file(export_dir.join(filename))
  end

  def restore_mongo(dir = 'mongo_dump')
    logger.info("restoring mongodump from #{export_dir.join(dir).relative_path_from(Rails.root)}")
    Mongo::Restore.from_dir(export_dir.join(dir))
  end
end

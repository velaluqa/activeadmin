require 'remote/sql/restore'
require 'remote/mongo/restore'

class RemoteRestore
  include FileUtils::Verbose
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

  def restore_configs
    logger.info("restoring form configs to #{ERICA.form_config_path.relative_path_from(Rails.root)}")
    system("rsync -avz #{Shellwords.escape(export_dir.join('forms').to_s)}/ #{Shellwords.escape(ERICA.form_config_path.to_s)}")
    logger.info("restoring session configs to #{ERICA.session_config_path.relative_path_from(Rails.root)}")
    system("rsync -avz #{Shellwords.escape(export_dir.join('sessions').to_s)}/ #{Shellwords.escape(ERICA.session_config_path.to_s)}")
    logger.info("restoring study configs to #{ERICA.study_config_path.relative_path_from(Rails.root)}")
    system("rsync -avz #{Shellwords.escape(export_dir.join('studies').to_s)}/ #{Shellwords.escape(ERICA.study_config_path.to_s)}")
  end
end

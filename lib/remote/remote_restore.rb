# coding: utf-8
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
    state_file = export_dir.join('.extracted')
    if state_file.exist?
      logger.info("already extracted #{relative(archive_file)} to #{relative(export_dir)}, skipping")
    else
      logger.info("extracting #{relative(archive_file)}")
      system_or_die("cd #{working_dir.shellescape}; lrzuntar #{archive_file.shellescape}")
      state_file.touch
    end
  end

  def restore_sql(filename)
    sql_file = export_dir.join(filename)
    state_file = export_dir.join(".#{filename}.restored")
    if state_file.exist?
      logger.info("already restored sql file #{relative(sql_file)}, skipping")
    else
      logger.info("restoring sql file #{relative(sql_file)}")
      Sql::Restore.from_file(sql_file)
      state_file.touch
    end
  end

  def restore_mongo(dir = 'mongo_dump')
    state_file = export_dir.join(".#{dir}.restored")
    mongo_dir = export_dir.join(dir)
    if state_file.exist?
      logger.info("already restored mongodump from #{relative(mongo_dir)}, skipping")
    else
      logger.info("restoring mongodump from #{relative(mongo_dir)}")
      Mongo::Restore.from_dir(mongo_dir)
      state_file.touch
    end
  end

  def restore_config_dir(dir, target)
    source = export_dir.join(dir)
    state_file = export_dir.join(".#{dir}.restored")
    if state_file.exist?
      logger.info("already restored #{dir.singularize} configs to #{relative(target)}, skipping")
    else
      logger.info("restoring #{dir.singularize} configs to #{relative(target)}")
      system_or_die("rsync -avz #{source.shellescape}/ #{target.shellescape}")
      state_file.touch
    end
  end

  def restore_configs
    restore_config_dir('forms', ERICA.form_config_path)
    restore_config_dir('sessions', ERICA.session_config_path)
    restore_config_dir('studies', ERICA.study_config_path)
  end

  def cleanup
    puts "#{working_dir}/*-*-*-*"
    Dir["#{working_dir}/*-*-*-*"].each do |path|
      next unless path =~ /^(\d{4}-\d{2}-\d{2})/
      path_date = Date.strptime($1, '%Y-%m-%d')
      next unless path_date < (Date.today - 7)
      puts "delete #{path}"
    end
  end

  private

  def relative(pathname)
    pathname.relative_path_from(Rails.root)
  end
end

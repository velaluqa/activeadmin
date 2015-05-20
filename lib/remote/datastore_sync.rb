require 'remote/remote'
require 'remote/mongo'
require 'remote/sql'

class Remote
  class DatastoreSync
    include FileUtils::Verbose
    include Logging

    attr_reader :export_id, :working_dir, :export_dir, :archive_file, :remote

    def self.perform(remote, options = {})
      DatastoreSync.new(remote, options).perform!
    end

    def initialize(remote, options = {})
      @remote       = Remote.new(remote)
      @export_id    =
        options[:export_id] || "#{Date.today.strftime('%Y-%m-%d')}-#{remote.name}"
      @working_dir  =
        Pathname.new(options[:working_dir] || Rails.root.join('tmp', 'remote_sync'))
      @export_dir   = working_dir.join(export_id)
      @archive_file = working_dir.join("#{export_id}.tar.lrz")
    end

    def perform!
      prepare
      dump_datastore
      compress_dump
      transfer_archive
      trigger_remote_restore
      cleanup
    end

    def prepare
      mkdir_p(export_dir)
    end

    def dump_datastore
      Sql.dump_upserts(export_dir.join('1_users.sql'))        {        User }
      Sql.dump_upserts(export_dir.join('2_studies.sql'))      {       Study.by_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('3_centers.sql'))      {      Center.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('4_patients.sql'))     {     Patient.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('5_visits.sql'))       {       Visit.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('6_image_series.sql')) { ImageSeries.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('7_images.sql'))       {       Image.by_study_ids(remote.study_ids) }

      Mongo.dump(
        collections: %w(patient_data visit_data image_series_data),
        out: export_dir,
        dir: 'mongo_dump'
      )

      cp_r(ERICA.config_paths, export_dir)
    end

    def compress_dump
      logger.info "compressing tarball #{archive_file.relative_path_from(Rails.root)}"
      system("cd #{Shellwords.escape(working_dir.to_s)}; lrztar -q -f -o #{Shellwords.escape(archive_file.to_s)} #{Shellwords.escape(export_id)}")
    end

    def transfer_archive
      logger.info 'transferring tarball to ERICA remote Server'

      remote.mkdir_p(remote.working_dir)
      remote.rsync_to(archive_file, remote.working_dir)
    end

    def trigger_remote_restore
      logger.info 'triggering restore job on ERICA remote server'
      remote.exec("cd #{remote.root}; ASYNC=no RAILS_ENV=#{Rails.env} bundle exec rake erica:remote:restore[#{export_id}]")
    end

    def cleanup
      logger.info 'cleaning up workspace'
      rm_rf(export_dir)
    end
  end
end

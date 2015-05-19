require 'remote/remote'
require 'remote/mongo'
require 'remote/sql'

class Remote
  class DatastoreSync
    include FileUtils::Verbose
    include Logging

    attr_reader :export_id, :working_dir, :export_dir, :archive_file, :remote

    def self.perform(options = {})
      DatastoreSync.new(options).perform!
    end

    def initialize(options = {})
      @export_id    = options.fetch(:export_id)
      @remote       = Remote.new(options.fetch(:remote))
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
      # dump SQL
      Sql.dump_upserts(export_dir.join('1_users.sql'))        {        User }
      Sql.dump_upserts(export_dir.join('2_studies.sql'))      {       Study.by_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('3_centers.sql'))      {      Center.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('4_patients.sql'))     {     Patient.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('5_visits.sql'))       {       Visit.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('6_image_series.sql')) { ImageSeries.by_study_ids(remote.study_ids) }
      Sql.dump_upserts(export_dir.join('7_images.sql'))       {       Image.by_study_ids(remote.study_ids) }

      # dump mongodb
      Mongo.dump(
        collections: %w(patient_data visit_data image_series_data),
        out: export_dir,
        dir: 'mongo_dump'
      )

      cp_r(ERICA.config_paths, export_dir)
    end

    def compress_dump
      logger.info "Compressing tarball #{archive_file.relative_path_from(Rails.root)}"
      system("cd #{Shellwords.escape(working_dir.to_s)}; lrztar -q -f -o #{Shellwords.escape(archive_file.to_s)} #{Shellwords.escape(export_id)}")
    end

    def transfer_archive
      logger.info 'Transferring tarball to ERICA remote Server'
      system("mkdir -p #{Shellwords.escape(remote.working_dir.to_s)}")
      system("rsync -az #{Shellwords.escape(archive_file.to_s)} #{Shellwords.escape(remote.working_dir.join('').to_s)}")
    end

    def trigger_remote_restore
      logger.info 'Triggering restore job on ERICA remote server'
      system("cd #{remote.root}; ASYNC=no RAILS_ENV=#{Rails.env} bundle exec rake erica:remote:restore[#{export_id}]")
    end

    def cleanup
      # delete dump folder only keep archive
    end
  end
end

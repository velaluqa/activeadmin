# coding: utf-8
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

    def dumped_datastore?
      export_dir.join('.state.dumped').exist?
    end

    def dump_datastore
      if dumped_datastore? || compressed_dump?
        logger. info "already dumped datastore for #{export_id}, skipping"
        return
      end

      user_options = {
        username: 'user{{:id}}',
        name: 'user{{:id}}',
        encrypted_password: '',
        private_key: :nil,
        public_key: :nil,
        current_sign_in_at: :nil,
        current_sign_in_ip: :nil,
        authentication_token: :nil,
        last_sign_in_at: :nil,
        last_sign_in_ip: :nil,
        locked_at: :nil,
        password_changed_at: :nil,
        remember_created_at: :nil,
        reset_password_sent_at: :nil,
        reset_password_token: :nil,
        sign_in_count: :nil,
        unlock_token: :nil
      }
      Sql.dump_upserts(export_dir.join('1_users.sql'), override_values: user_options) { User }
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

      export_dir.join('.state.dumped').touch
    end

    def compressed_dump?
      archive_file.exist?
    end

    def compress_dump
      if compressed_dump?
        logger.info "already compressed dump to #{relative(archive_file)}"
      else
        logger.info "compressing tarball #{relative(archive_file)}"
        system_or_die("cd #{working_dir.shellescape}; lrztar -q -f -o #{archive_file.shellescape} #{export_id.shellescape}")
      end
    end

    def transferred_archive?
      remote.file_exists?(remote.working_dir.join(archive_file.basename))
    end

    def transfer_archive
      if transferred_archive?
        logger.info "already transferred archive to #{remote.working_dir.join(archive_file.basename)}"
      else
        logger.info 'transferring tarball to ERICA remote Server'
        remote.mkdir_p(remote.working_dir)
        remote.rsync_to(archive_file, remote.working_dir)
      end
    end

    def trigger_remote_restore
      logger.info 'triggering restore job on ERICA remote server'
      remote.exec("cd #{remote.root.shellescape}; ASYNC=no RAILS_ENV=#{Rails.env} bundle exec rake erica:remote:restore[#{export_id}]")
    end

    def cleanup
      logger.info 'cleaning up workspace'
      rm_rf(export_dir)
    end

    private

    def relative(pathname)
      pathname.relative_path_from(Rails.root)
    end
  end
end

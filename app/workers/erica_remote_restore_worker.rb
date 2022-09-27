require 'remote/remote_restore'
require 'sidekiq_background_job'

class ERICARemoteRestoreWorker
  include SidekiqBackgroundJob
  
  def perform_job(export_id)
    remote = RemoteRestore.new(export_id)

    remote.extract_archive!

    remote.restore_sql('1_users.sql')
    remote.restore_sql('2_studies.sql')
    remote.restore_sql('3_centers.sql')
    remote.restore_sql('4_patients.sql')
    remote.restore_sql('5_visits.sql')
    remote.restore_sql('6_image_series.sql')
    remote.restore_sql('7_images.sql')

    remote.restore_configs

    remote.cleanup

    succeed!
  end
end

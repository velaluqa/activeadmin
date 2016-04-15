class MigrateBackgroundJobs < ActiveRecord::Migration
  def up
    unless Rails.configuration.mongoid.clients['default'].blank?
      require 'legacy/models/background_job'

      progress = ProgressBar.create(
        title: 'Migrating Background Jobs',
        total: Legacy::BackgroundJob.count,
        format: '%t |%B| %a / %E (%p%%)'
      )
      Legacy::BackgroundJob.all.each do |legacy_job|
        attributes = legacy_job.attributes
        attributes['legacy_id'] = attributes.delete('_id').to_s
        ::BackgroundJob.where(legacy_id: legacy_job._id).first_or_create(attributes)

        progress.increment
      end
    end
  end

  def down
    unless Rails.configuration.mongoid.clients['default'].blank?
      require 'legacy/models/background_job'

      progress = ProgressBar.create(
        title: 'Reverting Background Jobs',
        total: Legacy::BackgroundJob.count,
        format: '%t |%B| %a / %E (%p%%)'
      )
      Legacy::BackgroundJob.all.each do |legacy_job|
        ::BackgroundJob
          .where(legacy_id: legacy_job._id.to_s)
          .destroy_all

        progress.increment
      end
    end
  end
end

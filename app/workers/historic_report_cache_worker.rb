# Allows to perform historic cache generation in a sidekiq worker.
class HistoricReportCacheWorker
  include Sidekiq::Worker

  sidekiq_options(
    unique: :until_timeout,
    unique_expiration: 4.hours
  )

  def perform(query_id, study_id)
    query = HistoricReportQuery.find(query_id)
    query.calculate_cache(study_id)
  end
end

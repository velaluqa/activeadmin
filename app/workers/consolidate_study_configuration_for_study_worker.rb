class ConsolidateStudyConfigurationForStudyWorker
  include Sidekiq::Worker

  sidekiq_options(queue: :default, retry: 5)

  def perform(study_id, version = nil, user_id = nil)
    ::PaperTrail.request.whodunnit = user_id
    Study::Operation::ConsolidateStudyConfiguration.call(
      params: {
        study_id: study_id,
        version: version
      }
    )
  ensure
    ::PaperTrail.request.whodunnit = nil
  end
end

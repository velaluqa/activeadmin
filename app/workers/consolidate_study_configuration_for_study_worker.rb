class ConsolidateStudyConfigurationForStudyWorker
  include Sidekiq::Worker

  sidekiq_options(queue: :default, retry: 5)

  def perform(study_id, version = nil, user_id = nil)
    ::PaperTrail.whodunnit = user_id
    Study::ConsolidateStudyConfiguration.call(
      params: {
        study_id: study_id,
        version: version
      }
    )
  ensure
    ::PaperTrail.whodunnit = nil
  end
end

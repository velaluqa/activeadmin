class DominoTrashWorker
  include Sidekiq::Worker

  sidekiq_options(queue: :domino)

  # This worker is designed to throw exceptions on all errors/misuses, since Sidekiq handles those nicely

  def perform(study_domino_db_url, domino_unid, domino_document_form)
    client = DominoIntegrationClient.new(study_domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      raise 'Failed to communicate with the Domino server.'
      return
    end

    client.trash_document(domino_unid, domino_document_form)
  end
end

class DominoSyncWorker
  include Sidekiq::Worker

  # This worker is designed to throw exceptions on all errors/misuses, since Sidekiq handles those nicely

  def perform(resource_class_name, resource_id)
    # I am not sure whether I like this, admittedly convenient, way of doing it.
    # There are no checks as to what classes are passed in :/
    begin
      resource = resource_class_name.constantize.find(resource_id)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn 'Record not found for Domino sync: ' + e.message
      return true
    end

    resource.domino_sync
  end
end

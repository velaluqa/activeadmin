require 'domino_integration_client'

module DominoDocument
  def self.included(base)
    if !Rails.application.config.is_erica_remote && base.respond_to?(:after_commit) && base.respond_to?(:after_destroy)
      base.after_commit :schedule_domino_sync
      base.after_destroy :schedule_domino_document_trashing
    end
  end

  def domino_integration_enabled?
    (!Rails.application.config.is_erica_remote && !study.nil? && study.domino_integration_enabled?)
  end

  def lotus_notes_url
    study.notes_links_base_uri + domino_unid unless domino_unid.nil? || study.notes_links_base_uri.nil?
  end

  def domino_document
    return nil unless domino_integration_enabled?
    return nil if domino_unid.nil?

    client = DominoIntegrationClient.new(study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      Rails.logger.error 'Failed to communicate with the Domino server.'
    end

    client.get_document_by_unid(domino_unid)
  end

  def schedule_domino_sync
    DominoSyncWorker.perform_async(self.class.to_s, id)
  end

  def ensure_domino_document_exists
    # this is the case if this after_save callback was called for the very save action done is this callback
    # if we wouldn't catch this, we could end up in an infinite loop
    return true if respond_to?(:previous_changes) && previous_changes.include?('domino_unid')

    return true unless domino_integration_enabled?

    client = DominoIntegrationClient.new(study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      raise 'Failed to create Domino Integration Client.'
      return false
    end

    error_message = nil
    if domino_unid.nil?
      self.domino_unid = client.ensure_document_exists(domino_document_query, domino_document_form, domino_document_properties(:create), domino_document_properties(:update))
      result = !domino_unid.nil?
      error_message = 'Failed to create new document or find/update existing via query.'
    else
      result = client.update_document(domino_unid, domino_document_form, domino_document_properties(:update))
      if result == :'404'
        self.domino_unid = client.create_document(domino_document_form, domino_document_properties(:create))
        result = !domino_unid.nil?
        error_message = 'Failed to create new document after 404.'
      end
      error_message = 'Failed to update document.' if result == false
    end
    raise error_message if result == false

    result &&= save if is_a?(ActiveRecord::Base) && !changes.empty?

    result
  end

  def update_domino_document(changed_properties)
    return true unless domino_integration_enabled?

    return ensure_document_exists if domino_unid.nil?

    client = DominoIntegrationClient.new(study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      raise 'Failed to create Domino Integration Client.'
      return false
    end

    result = client.update_document(domino_unid, domino_document_form, changed_properties)
    raise 'Failed to update document.' if result == false

    result
  end

  def schedule_domino_document_trashing
    return true unless domino_integration_enabled?

    return true if domino_unid.nil?

    DominoTrashWorker.perform_async(study.domino_db_url, domino_unid, domino_document_form)
  end

  def set_domino_unid(domino_unid)
    return unless is_a?(ActiveRecord::Base)
    self.domino_unid = domino_unid
    save

    if Rails.application.config.domino_integration_readonly == :erica_id_only || Rails.application.config.domino_integration_readonly == false
      update_domino_document('ericaID' => id)
    end
  end
end

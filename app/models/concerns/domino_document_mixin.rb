require 'domino_integration_client'

module DominoDocument
  def self.included(base)
    if(not Rails.application.config.is_erica_remote and base.respond_to?(:after_commit) and base.respond_to?(:after_destroy))
      base.after_commit :schedule_domino_sync
      base.after_destroy :schedule_domino_document_trashing
    end
  end

  def domino_integration_enabled?
    (not Rails.application.config.is_erica_remote and not self.study.nil? and self.study.domino_integration_enabled?)
  end

  def lotus_notes_url
    self.study.notes_links_base_uri + self.domino_unid unless (self.domino_unid.nil? or self.study.notes_links_base_uri.nil?)
  end


  def domino_document
    return nil unless domino_integration_enabled?
    return nil if self.domino_unid.nil?

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      Rails.logger.error 'Failed to communicate with the Domino server.'
    end

    return client.get_document_by_unid(self.domino_unid)
  end

  def schedule_domino_sync
    DominoSyncWorker.perform_async(self.class.to_s, self.id)
  end

  def ensure_domino_document_exists
    # this is the case if this after_save callback was called for the very save action done is this callback
    # if we wouldn't catch this, we could end up in an infinite loop
    return true if(self.respond_to?(:previous_changes) and self.previous_changes.include?('domino_unid'))

    return true unless domino_integration_enabled?

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      raise 'Failed to create Domino Integration Client.'
      return false
    end

    error_message = nil
    if self.domino_unid.nil?
      self.domino_unid = client.ensure_document_exists(domino_document_query, domino_document_form, domino_document_properties(:create), domino_document_properties(:update))
      result = (not self.domino_unid.nil?)      
      error_message = 'Failed to create new document or find/update existing via query.'
    else
      result = client.update_document(self.domino_unid, domino_document_form, domino_document_properties(:update))
      if(result == :'404')
        self.domino_unid = client.create_document(domino_document_form, domino_document_properties(:create))
        result = (not self.domino_unid.nil?)
        error_message = 'Failed to create new document after 404.'
      end
      error_message = 'Failed to update document.' if(result == false)
    end
    raise error_message if (result == false)

    if(self.is_a?(ActiveRecord::Base) and not self.changes.empty?)
      result &&= self.save
    end

    return result
  end

  def update_domino_document(changed_properties)
    return true unless domino_integration_enabled?

    return self.ensure_document_exists if self.domino_unid.nil?
    
    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      raise 'Failed to create Domino Integration Client.'
      return false
    end

    result = client.update_document(self.domino_unid, domino_document_form, changed_properties)
    raise 'Failed to update document.' if (result == false)

    return result
  end

  def schedule_domino_document_trashing
    return true unless domino_integration_enabled?

    return true if self.domino_unid.nil?

    DominoTrashWorker.perform_async(self.study.domino_db_url, self.domino_unid, domino_document_form)
  end

  def set_domino_unid(domino_unid)
    return unless self.is_a?(ActiveRecord::Base)
    self.domino_unid = domino_unid
    self.save

    if(Rails.application.config.domino_integration_readonly == :erica_id_only or Rails.application.config.domino_integration_readonly == false)
      self.update_domino_document({'ericaID' => self.id})
    end
  end
end

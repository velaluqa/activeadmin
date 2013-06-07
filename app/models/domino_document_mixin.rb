require 'domino_integration_client'

module DominoDocument
  def self.included(base)
    base.after_commit :ensure_domino_document_exists
    base.after_destroy :trash_document
  end

  def domino_integration_enabled?
    (not self.study.nil? and self.study.domino_integration_enabled?)
  end

  def lotus_notes_url
    self.study.notes_links_base_uri + self.domino_unid unless (self.domino_unid.nil? or self.study.notes_links_base_uri.nil?)
  end

  def domino_document_needs_update?
    not (self.previous_changes.keys & domino_document_fields).empty?
  end

  def domino_document
    return nil unless domino_integration_enabled?
    return nil if self.domino_unid.nil?

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      Rails.logger.error 'Failed to communicate with the Domino server.'
      return nil
    end

    return client.get_document_by_unid(self.domino_unid)
  end

  def ensure_domino_document_exists
    # this is the case if this after_save callback was called for the very save action done is this callback
    # if we wouldn't catch this, we could end up in an infinite loop
    return true if self.previous_changes.include?('domino_unid')

    return true unless domino_integration_enabled?

    return true unless(domino_document_needs_update? or self.domino_unid.nil?)

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      errors.add :name, 'Failed to communicate with the Domino server.'
      return false
    end

    if self.domino_unid.nil?
      self.domino_unid = client.ensure_document_exists(domino_document_query, domino_document_form, domino_document_properties)
      result = (not self.domino_unid.nil?)      
    else
      result = client.update_document(self.domino_unid, domino_document_form, domino_document_properties)
    end
    errors.add :name, 'Failed to communicate with the Domino server.' if (result == false)

    unless self.changes.empty?
      result &&= self.save
    end

    return result
  end

  def update_domino_document(changed_properties)
    return true unless domino_integration_enabled?

    return self.ensure_document_exists if self.domino_unid.nil?
    
    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      errors.add :name, 'Failed to communicate with the Domino server.'
      return false
    end

    result = client.update_document(self.domino_unid, domino_document_form, changed_properties)
    errors.add :name, 'Failed to communicate with the Domino server.' if (result == false)

    return result
  end

  def trash_document
    return true unless domino_integration_enabled?

    return true if self.domino_unid.nil?

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      errors.add :name, 'Failed to communicate with the Domino server.'
      return false
    end

    return client.trash_document(self.domino_unid, domino_document_form)
  end

  def set_domino_unid(domino_unid)
    self.domino_unid = domino_unid
    self.save

    if(Rails.application.config.domino_integration_readonly == :erica_id_only or Rails.application.config.domino_integration_readonly == false)
      self.update_domino_document({'ericaID' => self.id})
    end
  end
end

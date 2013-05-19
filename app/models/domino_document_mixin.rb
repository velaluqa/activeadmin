require 'domino_integration_client'

module DominoDocument
  def self.included(base)
    base.after_commit :ensure_domino_document_exists
    base.after_destroy :trash_document
  end

  def lotus_notes_url
    self.study.notes_links_base_uri + self.domino_unid unless (self.domino_unid.nil? or self.study.notes_links_base_uri.nil?)
  end

  def domino_document_needs_update?
    not (self.previous_changes.keys & domino_document_fields).empty?
  end

  def ensure_domino_document_exists
    # this is the case if this after_save callback was called for the very save action done is this callback
    # if we wouldn't catch this, we could end up in an infinite loop
    return true if self.previous_changes.include?('domino_unid')

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

  def trash_document
    return true if self.domino_unid.nil?

    client = DominoIntegrationClient.new(self.study.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)
    if client.nil?
      errors.add :name, 'Failed to communicate with the Domino server.'
      return false
    end

    return client.trash_document(self.domino_unid, domino_document_form)
  end
end

module DominoDocument
  def self.included(base)
    base.before_save :ensure_domino_document_exists
  end

  def domino_document_needs_update?
    not (self.changes.keys & domino_document_fields).empty?
  end

  def ensure_domino_document_exists
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

    return result
  end
end

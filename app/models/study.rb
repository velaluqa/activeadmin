require 'git_config_repository'
require 'schema_validation'
require 'uri'
require 'domino_integration_client'

class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :locked_version, :domino_db_url, :notes_links_base_uri

  has_many :sessions

  has_many :roles, :as => :subject

  has_many :centers
  has_many :patients, :through => :centers
  has_many :visits, :through => :patients
  has_many :image_series, :through => :patients

  validates_presence_of :name

  before_destroy do
    unless(sessions.empty? and centers.empty?)
      errors.add :base, 'You cannot delete a study that still has sessions or centers associated with it.'
      return false
    end
  end

  before_save do
    if(self.changes.include?('domino_db_url'))
      update_notes_links_base_uri
    end
  end

  def previous_image_storage_path
    image_storage_path
  end
  def image_storage_path
    self.id.to_s
  end

  def config_file_path
    Rails.application.config.study_configs_directory + "/#{id}.yml"
  end
  def relative_config_file_path
    Rails.application.config.study_configs_subdirectory + "/#{id}.yml"
  end

  def current_configuration
    begin
      config = GitConfigRepository.new.yaml_at_version(relative_config_file_path, nil)
    rescue SyntaxError => e
      return nil
    end

    return config
  end
  def locked_configuration
    begin
      config = GitConfigRepository.new.yaml_at_version(relative_config_file_path, self.locked_version)
    rescue SyntaxError => e
      return nil
    end

    return config
  end
  def configuration_at_version(version)
    begin
      config = GitConfigRepository.new.yaml_at_version(relative_config_file_path, version)
    rescue SyntaxError => e
      return nil
    end

    return config
  end
  def has_configuration?
    File.exists?(self.config_file_path)
  end

  def semantically_valid?
    return self.validate == []
  end
  def validate
    return nil unless has_configuration?
    config = current_configuration
    return nil if config.nil?

    validation_errors = run_schema_validation(config)
    return validation_errors unless validation_errors == []

    return validation_errors
  end

  def visit_types
    return [] unless self.has_configuration?

    config = current_configuration
    
    return (config['visit_types'].nil? ? []: config['visit_types'].keys)
  end

  def wado_query
    self.patients.map {|patient| patient.wado_query}
  end

  def domino_integration_enabled?
    (not self.domino_db_url.blank? and not self.notes_links_base_uri.blank?)
  end
  def lotus_notes_url
    self.notes_links_base_uri
  end

  protected

  def run_schema_validation(config)
    validator = SchemaValidation::StudyValidator.new
    return nil if config.nil?

    validator.validate(config)
  end

  # Notes://<server>/<replica id>/<view id>/<document unid>
  def update_notes_links_base_uri
    return true if self.domino_db_url.blank?
    
    new_notes_links_base_uri = URI(self.domino_db_url)
    new_notes_links_base_uri.scheme = 'Notes'

    begin
      domino_integration_client = DominoIntegrationClient.new(self.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)

      replica_id = domino_integration_client.replica_id
      collection_unid = domino_integration_client.collection_unid('All')
    rescue SystemCallError => e
      Rails.logger.warn "Failed to communicate with the Domino server: #{e.message}"
      errors.add :domino_db_url, "Failed to communicate with the Domino server: #{e.message}"
    end

    if(replica_id.nil? or collection_unid.nil?)
      self.notes_links_base_uri = nil
      false
    else
      new_notes_links_base_uri.path = "/#{replica_id}/#{collection_unid}/"
      self.notes_links_base_uri = new_notes_links_base_uri.to_s
      true      
    end
  end
end

# coding: utf-8
require 'git_config_repository'
require 'schema_validation'
require 'uri'
require 'domino_integration_client'

# ## Schema Information
#
# Table name: `studies`
#
# ### Columns
#
# Name                        | Type               | Attributes
# --------------------------- | ------------------ | ---------------------------
# **`created_at`**            | `datetime`         |
# **`domino_db_url`**         | `string`           |
# **`domino_server_name`**    | `string`           |
# **`id`**                    | `integer`          | `not null, primary key`
# **`locked_version`**        | `string`           |
# **`name`**                  | `string`           |
# **`notes_links_base_uri`**  | `string`           |
# **`state`**                 | `integer`          | `default(0)`
# **`updated_at`**            | `datetime`         |
#
class Study < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  acts_as_taggable

  attr_accessible :name, :locked_version, :domino_db_url, :domino_server_name, :notes_links_base_uri, :state

  has_many :user_roles, :as => :scope_object, dependent: :destroy

  has_many :centers
  has_many :patients, :through => :centers
  has_many :visits, :through => :patients
  has_many :image_series, :through => :patients
  has_many :images, :through => :image_series

  validates_presence_of :name

  scope :building, -> { where(state: 0) }
  scope :production, -> { where(state: 1) }

  scope :by_ids, ->(*ids) { where(id: Array[ids].flatten) }

  scope :searchable, -> { select(<<SELECT) }
studies.id AS study_id,
studies.name AS text,
studies.id AS result_id,
'Study' AS result_type
SELECT

  include ImageStorageCallbacks

  include ScopablePermissions

  def self.with_permissions
    joins(<<JOIN)
LEFT JOIN "centers" ON "centers"."study_id" = "studies"."id"
LEFT JOIN "patients" ON "patients"."center_id" = "centers"."id"
INNER JOIN user_roles ON
  (
       (user_roles.scope_object_type = 'Study'   AND user_roles.scope_object_id = studies.id)
    OR (user_roles.scope_object_type = 'Center'  AND user_roles.scope_object_id = centers.id)
    OR (user_roles.scope_object_type = 'Patient' AND user_roles.scope_object_id = patients.id)
    OR user_roles.scope_object_id IS NULL
  )
INNER JOIN roles ON user_roles.role_id = roles.id
INNER JOIN permissions ON roles.id = permissions.role_id
JOIN
  end

  before_destroy do
    unless centers.empty?
      errors.add :base, 'You cannot delete a study that still has centers associated with it.'
      return false
    end
  end

  before_save do
    if(self.changes.include?('domino_db_url') or self.changes.include?('domino_server_name'))
      update_notes_links_base_uri
    end
  end

  STATE_SYMS = [:building, :production]

  def self.state_sym_to_int(sym)
    return Study::STATE_SYMS.index(sym)
  end
  def self.int_to_state_sym(sym)
    return Study::STATE_SYMS[sym]
  end
  def state
    return -1 if read_attribute(:state).nil?
    return Study::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    if sym.is_a? Fixnum
      index = sym
    else
      index = Study::STATE_SYMS.index(sym)
    end

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end

  def image_storage_path
    id.to_s
  end
  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + self.image_storage_path
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
  def locked_semantically_valid?
    return self.validate(self.locked_version) == []
  end
  def semantically_valid_at_version?(version)
    return self.validate(version) == []
  end
  def validate(version = nil)
    return nil unless has_configuration?
    if(version.nil?)
      config = current_configuration
    else
      config = configuration_at_version(version)
    end
    return nil if config.nil?

    validation_errors = run_schema_validation(config)
    return validation_errors unless validation_errors == []

    return validation_errors
  end

  def visit_types
    return [] unless has_configuration?
    return [] unless current_configuration['visit_types'].is_a?(Hash)
    current_configuration['visit_types'].keys
  end

  def visit_templates
    return {} unless has_configuration?
    return {} unless current_configuration['visit_templates'].is_a?(Hash)
    current_configuration['visit_templates']
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

  def to_s
    name
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
    begin
      new_notes_links_base_uri.host = self.domino_server_name unless self.domino_server_name.blank?
    rescue URI::InvalidComponentError => e
      errors[:domino_server_name] = 'Invalid format: '+e.message
      return false
    end
    new_notes_links_base_uri.scheme = 'Notes'

    begin
      domino_integration_client = DominoIntegrationClient.new(self.domino_db_url, Rails.application.config.domino_integration_username, Rails.application.config.domino_integration_password)

      replica_id = domino_integration_client.replica_id
      collection_unid = domino_integration_client.collection_unid('All')
    rescue Exception => e
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

  def self.classify_audit_trail_event(c)
    if(c.keys == ['name'])
      :name_change
    elsif(c.include?('state'))
      case [int_to_state_sym(c['state'][0].to_i), c['state'][1]]
      when [:building, :production] then :production_start
      when [:production, :building] then :production_abort
      else :state_change
      end
    elsif((c.keys - ['domino_db_url', 'domino_server_name', 'notes_links_base_uri']).empty?)
      return :domino_settings_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :production_start then ['Production started', :ok]
           when :production_abort then ['Production aborted', :error]
           when :state_change then ['State Change', :warning]
           when :name_change then ['Name Change', :ok]
           when :domino_settings_change then ['Domino Settings Change', :ok]
           end
  end
end

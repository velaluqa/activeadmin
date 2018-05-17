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
  has_paper_trail(
    class_name: 'Version',
    meta: {
      study_id: :id
    }
  )
  acts_as_taggable

  attr_accessible(
    :name,
    :locked_version,
    :domino_db_url,
    :domino_server_name,
    :notes_links_base_uri,
    :state
  )

  has_many :user_roles, as: :scope_object, dependent: :destroy

  has_many :centers
  has_many :patients, through: :centers
  has_many :visits, through: :patients
  has_many :image_series, through: :patients
  has_many :images, through: :image_series
  has_many :required_series, through: :visits

  validates_presence_of :name

  scope :building, -> { where(state: 0) }
  scope :production, -> { where(state: 1) }

  scope :by_ids, ->(*ids) { where(id: Array[ids].flatten) }

  scope :searchable, -> { select(<<SELECT.strip_heredoc) }
    studies.id AS study_id,
    studies.name AS study_name,
    studies.name AS text,
    studies.id AS result_id,
    'Study'::varchar AS result_type
SELECT

  include ImageStorageCallbacks

  include ScopablePermissions

  def self.with_permissions
    joins(<<JOIN.strip_heredoc)
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
    if changes.include?('domino_db_url') || changes.include?('domino_server_name')
      update_notes_links_base_uri
    end
  end

  STATE_SYMS = %i[building production].freeze

  def self.state_sym_to_int(sym)
    Study::STATE_SYMS.index(sym)
  end

  def self.int_to_state_sym(sym)
    Study::STATE_SYMS[sym]
  end

  def state
    return -1 if read_attribute(:state).nil?
    Study::STATE_SYMS[read_attribute(:state)]
  end

  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index =
      if sym.is_a? Integer
        sym
      else
        Study::STATE_SYMS.index(sym)
      end

    if index.nil?
      throw 'Unsupported state'
      return
    end

    write_attribute(:state, index)
  end

  def image_storage_path
    id.to_s
  end

  def absolute_image_storage_path
    Rails.application.config.image_storage_root + '/' + image_storage_path
  end

  def config_file_path
    Rails.application.config.study_configs_directory + "/#{id}.yml"
  end

  def relative_config_file_path
    Rails.application.config.study_configs_subdirectory + "/#{id}.yml"
  end

  def current_configuration
    GitConfigRepository.new.yaml_at_version(relative_config_file_path, nil)
  rescue SyntaxError => _e
    nil
  end

  def locked_configuration
    GitConfigRepository.new.yaml_at_version(relative_config_file_path, locked_version)
  rescue SyntaxError => _e
    nil
  end

  def configuration_at_version(version)
    GitConfigRepository.new.yaml_at_version(relative_config_file_path, version)
  rescue SyntaxError => _e
    nil
  end

  def has_configuration?
    File.exist?(config_file_path)
  end

  def semantically_valid?
    validate == []
  end

  def locked_semantically_valid?
    validate(locked_version) == []
  end

  def semantically_valid_at_version?(version)
    validate(version) == []
  end

  def validate(version = nil)
    return nil unless has_configuration?
    config = if version.nil?
               current_configuration
             else
               configuration_at_version(version)
             end
    return nil if config.nil?

    validation_errors = run_schema_validation(config)
    return validation_errors unless validation_errors == []

    validation_errors
  end

  def lock_configuration!
    self.state = :production
    self.locked_version = GitConfigRepository.new.current_version
    save!
  end

  def unlock_configuration!
    self.state = :building
    self.locked_version = nil
    save!
  end

  def update_configuration!(config, user: nil)
    repo = GitConfigRepository.new
    repo.update_config_file(relative_config_file_path, config, user, "New configuration file for study #{id}")
  end

  # Returns configured visit_type specification.
  #
  # @param [String] version the version to get the visit types for
  # @return [Hash] hash with visit type specification
  def visit_type_spec(version: nil)
    config = configuration(version: version)
    return {} unless config
    return {} unless config['visit_types'].is_a?(Hash)
    config['visit_types']
  end

  # Returns configured visit type namesx.
  #
  # @param [String] version the version to get the visit types for
  # @return [Array] array with visit type names
  def visit_types(version: nil)
    visit_type_spec(version: version).keys
  end

  def visit_templates(version: nil)
    config = configuration(version: version)
    return {} unless config
    return {} unless config['visit_templates'].is_a?(Hash)
    config['visit_templates']
  end

  # Returns configured required series specification for a specified
  # `visit_type`.
  #
  # @param [String] visit_type the name of the visit type
  # @param [String] version the version to get the required series for
  # @return [Hash] hash with required series specification
  def required_series_spec(visit_type, version: nil)
    visit_types = visit_type_spec(version: version)
    return {} unless visit_types[visit_type].is_a?(Hash)
    return {} unless visit_types[visit_type]['required_series'].is_a?(Hash)
    visit_types[visit_type]['required_series']
  end

  # Returns configured required series names for a specified
  # `visit_type`.
  #
  # @param [String] visit_type the name of the visit type
  # @param [String] version the version to get the required series for
  # @return [Array] array of required series names
  def required_series_names(visit_type, version: nil)
    required_series_spec(visit_type, version: version).keys
  end

  def locked?
    locked_version.present?
  end

  def configuration(version: nil)
    version ||= locked? ? :locked : :current
    if version == :locked
      locked_configuration
    elsif version == :current
      current_configuration
    else
      configuration_at_version(version)
    end
  end

  def wado_query
    patients.map(&:wado_query)
  end

  def domino_integration_enabled?
    (!domino_db_url.blank? && !notes_links_base_uri.blank?)
  end

  def lotus_notes_url
    notes_links_base_uri
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
    return true if domino_db_url.blank?

    new_notes_links_base_uri = URI(domino_db_url)
    new_notes_links_base_uri.host = domino_server_name unless domino_server_name.blank?
    new_notes_links_base_uri.scheme = 'Notes'

    domino_integration_client = DominoIntegrationClient.new(
      domino_db_url,
      Rails.application.config.domino_integration_username,
      Rails.application.config.domino_integration_password
    )

    replica_id = domino_integration_client.replica_id
    collection_unid = domino_integration_client.collection_unid('All')

    if replica_id.nil?
      errors.add(:domino_db_url, 'Could not find Domino Replica. Note: Domino Db Url is case-sensitive.')
      return false
    end

    if collection_unid.nil?
      errors.add(:domino_db_url, 'Could not find Domino Collection. Note: Domino Db Url is case-sensitive.')
      return false
    end

    new_notes_links_base_uri.path = "/#{replica_id}/#{collection_unid}/"
    self.notes_links_base_uri = new_notes_links_base_uri.to_s
    true
  rescue URI::InvalidComponentError => e
    errors.add :domino_db_url, "Invalid format: #{e.message}"
    false
  rescue DominoIntegrationClient::CommandError => e
    errors.add :domino_db_url, "Communication error: #{e.message}"
    false
  rescue StandardError => e
    errors.add :domino_db_url, e.message
    false
  end

  def self.classify_audit_trail_event(c)
    if c.keys == ['name']
      :name_change
    elsif c.include?('state')
      case [int_to_state_sym(c['state'][0].to_i), c['state'][1]]
      when %i[building production] then :production_start
      when %i[production building] then :production_abort
      else :state_change
      end
    elsif (c.keys - %w[domino_db_url domino_server_name notes_links_base_uri]).empty?
      :domino_settings_change
    end
  end

  def self.audit_trail_event_title_and_severity(event_symbol)
    case event_symbol
    when :production_start then ['Production started', :ok]
    when :production_abort then ['Production aborted', :error]
    when :state_change then ['State Change', :warning]
    when :name_change then ['Name Change', :ok]
    when :domino_settings_change then ['Domino Settings Change', :ok]
    end
  end
end

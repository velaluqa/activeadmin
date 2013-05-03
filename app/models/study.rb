require 'git_config_repository'
require 'schema_validation'

class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :locked_version

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
    return if config.nil?

    validation_errors = run_schema_validation(config)
    return validation_errors unless validation_errors == []

    return validation_errors
  end

  def wado_query
    self.patients.map {|patient| patient.wado_query}
  end

  protected

  def run_schema_validation(config)
    validator = SchemaValidation::StudyValidator.new
    return nil if config.nil?

    validator.validate(config)
  end

end

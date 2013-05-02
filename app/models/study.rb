require 'git_config_repository'
require 'schema_validation'

class Study < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name

  has_many :sessions

  has_many :roles, :as => :subject

  has_many :centers

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

end

require 'git_config_repository'
require 'schema_validation'

class Session < ActiveRecord::Base
  has_paper_trail

  attr_accessible :name, :study, :study_id, :state, :locked_version

  belongs_to :study

  has_many :roles, :as => :subject
  has_many :form_answers
  has_many :patients
  has_many :forms
  has_many :cases

  has_and_belongs_to_many :readers, :class_name => 'User', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validators, :class_name => 'User', :join_table => 'validators_sessions'

  scope :blind_readable_by_user, lambda { |user| user.blind_readable_sessions.includes(:study) }
  scope :building, where(:state => 0)
  scope :testing, where(:state => 1)
  scope :production, where(:state => 2)
  scope :closed, where(:state => 3)

  before_destroy do
    unless form_answers.empty? and patients.empty? and forms.empty? and cases.empty?
      errors.add :base, 'You cannot delete a session unless all associated data was deleted first.'
      return false
    end

    self.roles.destroy_all
  end

  STATE_SYMS = [:building, :testing, :production, :closed]

  def self.state_sym_to_int(sym)
    return Session::STATE_SYMS.index(sym)
  end
  def state
    return -1 if read_attribute(:state).nil?
    return Session::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Session::STATE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end

  def form_answers
    return FormAnswer.where(:session_id => self.id)
  end
  
  def config_file_path
    Rails.application.config.session_configs_directory + "/#{id}.yml"
  end
  def relative_config_file_path
    Rails.application.config.session_configs_subdirectory + "/#{id}.yml"
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

    validation_errors = run_schema_validation
    return validation_errors unless validation_errors == []

    included_forms.each do |included_form|
      validation_errors << "Included form '#{included_form}' is missing" if Form.where(:name => included_form, :session_id => self.id).empty?
    end
    if(config['reader_testing'])
      validation_errors << "Reader testing case type '#{config['reader_testing']['case_type']}' does not exist" if config['types'][config['reader_testing']['case_type']].nil?
      validation_errors << "Reader testing patient '#{config['reader_testing']['patient']}' does not exist" if Patient.where(:subject_id => config['reader_testing']['patient'], :session_id => self.id).empty?
    end

    return validation_errors
  end

  def included_forms
    config = current_configuration
    return [] unless self.run_schema_validation == []

    return config['types'].reject{|name,t| t['form'].nil?}.map{|name,t| t['form'].to_s}
  end

  def case_list(mode = :unread)
    flag = (self.state == :testing ? :validation : :regular)
    case mode
    when :unread
      self.cases.where(:state => Case::state_sym_to_int(:unread), :flag => Case::flag_sym_to_int(flag)).reject {|c| not c.form_answer.nil? }
    when :in_progress
      self.cases.where(:state => Case::state_sym_to_int(:in_progress), :flag => Case::flag_sym_to_int(flag))
    when :read
      self.cases.where(:state => Case::state_sym_to_int(:read), :flag => Case::flag_sym_to_int(flag)).reject {|c| c.form_answer.nil? }
    when :reopened
      self.cases.where(:state => Case::state_sym_to_int(:reopened), :flag => Case::flag_sym_to_int(flag)).reject {|c| c.form_answer.nil? }
    when :reopened_in_progress
      self.cases.where(:state => Case::state_sym_to_int(:reopened_in_progress), :flag => Case::flag_sym_to_int(flag)).reject {|c| c.form_answer.nil? }
    when :all
      self.cases.where(:flag => Case::flag_sym_to_int(flag))
    end
  end

  def reserve_next_case
    c = case_list(:unread).first
    return nil if c.nil?
    c.state = :in_progress
    c.save

    return c
  end
  def next_unread_case
    case_list(:unread).first
  end
  def last_read_case
    case_list(:read).last    
  end

  def next_position
    return 0 if self.cases.empty?
    return self.cases.last.position+1
  end

  # fake attributes for formtastic
  # this is both disgusting and stupid, but still seems the most practical way :(
  def case_type
    nil
  end
  def annotations_layout_mode
    :regular
  end


  protected

  def run_schema_validation
    validator = SchemaValidation::SessionValidator.new
    config = current_configuration
    return nil if config.nil?

    validator.validate(config)
  end
  
end

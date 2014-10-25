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
      reader_testing_configs = config['reader_testing']['configs']
      reader_testing_configs ||= [config['reader_testing']]

      reader_testing_configs.each_with_index do |reader_testing_config, index|
        validation_errors << "The case type '#{reader_testing_config['case_type']}' for reader testing config number #{index+1} does not exist" if config['types'][reader_testing_config['case_type']].nil?
        validation_errors << "The patient '#{reader_testing_config['patient']}' for reader testing config number #{index+1} does not exist" if Patient.where(:subject_id => reader_testing_config['patient'], :session_id => self.id).empty?
      end
    end
    if(config['type'] == 'adjudication' and config['adjudication'])
      config['adjudication']['sessions'].each do |session_id|
        session = Session.where(:id => session_id).last
        validation_errors << "The adjudication base session #{session_id} does either not exist or is still being built." unless(session and session.state != :building)
      end
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
      self.cases.where(:state => Case::state_sym_to_int(:unread), :flag => Case::flag_sym_to_int(flag))
    when :in_progress
      self.cases.where(:state => Case::state_sym_to_int(:in_progress), :flag => Case::flag_sym_to_int(flag))
    when :read
      self.cases.where(:state => Case::state_sym_to_int(:read), :flag => Case::flag_sym_to_int(flag))
    when :reopened
      self.cases.where(:state => Case::state_sym_to_int(:reopened), :flag => Case::flag_sym_to_int(flag))
    when :reopened_in_progress
      self.cases.where(:state => Case::state_sym_to_int(:reopened_in_progress), :flag => Case::flag_sym_to_int(flag))
    when :all
      self.cases.where(:flag => Case::flag_sym_to_int(flag))
    end
  end

  def reserve_next_case_for_reader(min_position = 0, reader)
    flag = (self.state == :testing ? :validation : :regular)

    c = self.cases.where(:state => Case::state_sym_to_int(:unread), :flag => Case::flag_sym_to_int(flag), :is_adjudication_background_case => [false, nil]).where('position >= ?', min_position).reject {|c| not c.form_answer.nil? }.reject {|c| not c.assigned_reader.nil? and c.assigned_reader != reader }.first
    return nil if c.nil?
    c.state = :in_progress unless c.is_adjudication_background_case
    c.save

    return c
  end

  def next_position
    return 0 if self.cases.empty?
    return self.cases.last.position+1
  end

  def deep_clone(new_name, new_study, current_user, components)
    new_session = self.dup

    new_session.name = new_name
    new_session.study = new_study

    new_session.state = :building
    new_session.locked_version = nil
    new_session.save

    # forms
    if(components.include?(:forms))
      self.forms.each do |form|
        form.copy_to_session(new_session, current_user)
      end
    end
    
    # patients
    patient_mapping = {}
    if(components.include?(:patients) || components.include?(:cases))
      self.patients.each do |patient|
        new_patient = patient.dup
        new_patient.session = new_session
        new_patient.save

        unless(patient.patient_data.nil?)
          new_patient_data = patient.patient_data.clone
          new_patient_data.patient = new_patient
          new_patient_data.save
        end

        patient_mapping[patient.id] = new_patient.id
      end
    end

    # cases
    if(components.include?(:cases))
      self.cases.each do |c|
        next if c.flag == :reader_testing

        new_case = c.dup
        new_case.session = new_session
        new_case.patient_id = patient_mapping[c.patient_id]

        new_case.exported_at = nil
        new_case.state = :unread
        new_case.current_reader = nil

        new_case.save

        unless(c.case_data.nil?)
          new_case_data = c.case_data.clone
          new_case_data.case = new_case
          new_case_data.save
        end
      end
    end

    # readers
    new_session.readers = self.readers if(components.include?(:readers))

    # validators
    new_session.validators = self.validators if(components.include?(:validators))


    GitConfigRepository.new.update_config_file(new_session.relative_config_file_path, self.config_file_path, current_user, "Cloned session #{self.id}")
    new_session.save

    new_session
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

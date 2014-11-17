require 'git_config_repository'
require 'schema_validation'

class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description, :name, :session_id, :session, :state, :locked_version

  validates :name, :presence => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }
  validates_uniqueness_of :name, :scope => :session_id  

  belongs_to :session
  has_many :form_answers

  scope :draft, where(:state => 0)
  scope :final, where(:state => 1)

  before_destroy do
    unless self.form_answers.empty?
      errors.add :base, 'You cannot delete a form that has form answers associated with it'
      return false
    end
  end

  STATE_SYMS = [:draft, :final]

  def self.state_sym_to_int(sym)
    return Form::STATE_SYMS.index(sym)
  end
  def state
    return -1 if read_attribute(:state).nil?
    return Form::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    if sym.is_a? Fixnum
      index = sym
    else
      index = Form::STATE_SYMS.index(sym)
    end

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end

  def form_answers
    return FormAnswer.where(:form_id => self.id)
  end

  def copy_to_session(session, current_user)
    copied_form = self.dup
    copied_form.session = session
    copied_form.locked_version = nil
    copied_form.state = :draft
    copied_form.save

    git_config_repository = GitConfigRepository.new
    git_config_repository.update_config_file(copied_form.relative_config_file_path, self.config_file_path, current_user, "Copied form #{self.id} into session #{session.id}") if self.has_configuration?

    git_config_repository.update_config_file(copied_form.relative_validator_file_path, self.validator_file_path, current_user, "Copied form #{self.id} validators into session #{session.id}") if(self.has_configuration? and git_config_repository.file_exists_at_version?(self.relative_validator_file_path))
    git_config_repository.update_config_file(copied_form.relative_stylesheet_file_path, self.stylesheet_file_path, current_user, "Copied form #{self.id} stylesheets into session #{session.id}") if(self.has_configuration? and git_config_repository.file_exists_at_version?(self.relative_stylesheet_file_path))

    copied_form
  end

  def is_template?
    session_id.nil?
  end

  def full_current_configuration(include_all_repeatables = false)
    full_configuration(:current, nil, true, nil, include_all_repeatables)
  end
  def full_locked_configuration
    full_configuration(:locked)
  end
  def full_configuration_at_versions(versions)
    full_configuration(versions)
  end
  def full_configuration_at_versions_for_case(versions, the_case)
    full_configuration(versions, nil, true, the_case)
  end
  def current_configuration
    parse_config(:current)
  end
  def locked_configuration
    parse_config(:locked)
  end
  def configuration_at_version(version)
    parse_config(version)
  end
  def has_configuration?
    File.exists?(self.config_file_path)
  end

  def current_components
    components(:current)
  end
  def locked_components
    components(:locked)
  end
  def components_at_version(version)
    components(version)
  end

  def self.config_field_has_special_type?(field)
    ['include_start', 'include_divider', 'include_end', 'section', 'group'].include? field['type']
  end

  def relative_config_file_path
    Rails.application.config.form_configs_subdirectory + "/#{id}.yml"
  end
  def config_file_path
    Rails.application.config.form_configs_directory + "/#{id}.yml"
  end
  def relative_validator_file_path
    Rails.application.config.form_configs_subdirectory + "/#{id}.js"
  end
  def validator_file_path
    Rails.application.config.form_configs_directory + "/#{id}.js"
  end
  def relative_stylesheet_file_path
    Rails.application.config.form_configs_subdirectory + "/#{id}.css"
  end
  def stylesheet_file_path
    Rails.application.config.form_configs_directory + "/#{id}.css"
  end

  def included_forms
    config = current_configuration
    return [] if config.nil?

    return config.reject{|f| f['include'].nil?}.map{|f| f['include'].to_s}
  end

  def semantically_valid?
    return self.validate == []
  end
  def validate
    return nil unless has_configuration?

    validator = SchemaValidation::FormValidator.new
    config = current_configuration
    return nil if config.nil?

    validation_errors = validator.validate(config)
    return validation_errors unless validation_errors == []

    included_forms.each do |included_form|
      validation_errors << "Included form '#{included_form}' is missing" if Form.where(:name => included_form, :session_id => self.session_id).empty?
    end

    return validation_errors
  end

  protected

  def parse_version_sym(version, resolve_hash = true)
    case version
    when :current
      nil
    when :locked
      self.locked_version
    when Hash
      if(resolve_hash)
        version[self.id]
      else
        version
      end
    else
      version
    end
  end
  
  def parse_config(version)
    version = parse_version_sym(version)
    begin
      config = GitConfigRepository.new.yaml_at_version(relative_config_file_path, version)
    rescue SyntaxError => e
      return nil
    end
    
    return config
  end
  
  def components(version)
    version = parse_version_sym(version)
    id = read_attribute(:id)

    form_components = {:validators => [], :stylesheets => []}

    validator = GitConfigRepository.new.text_at_version(relative_validator_file_path, version)
    form_components[:validators] << validator unless validator.nil?

    stylesheet = GitConfigRepository.new.text_at_version(relative_stylesheet_file_path, version)
    form_components[:stylesheet] << stylesheet unless stylesheet.nil?

    return form_components
  end

  def stringify_form_components(components)
    components.each do |key, value|
      components[key] = value.join("\n")
    end
  end

  def full_configuration(versions, already_included_forms = nil, stringify = true, the_case = nil, include_all_repeatables = false)
    parsed_version = parse_version_sym(versions)
    form_config = parse_config(parsed_version)
    return [nil,nil,nil] if form_config.nil?
    form_components = components(parsed_version)
    return [nil,nil,nil] if form_components.nil?

    already_included_forms = [] if already_included_forms.nil?
    already_included_forms << read_attribute(:id)

    unless(the_case.nil? or the_case.form_answer.nil?)
      previous_answers = the_case.form_answer.answers
    end
    form_config, form_components, repeatables = process_imports(form_config, form_components, already_included_forms, read_attribute(:session_id), versions, previous_answers, include_all_repeatables)
    form_components = stringify_form_components(form_components) if stringify

    return [form_config, form_components, repeatables]
  end
  def process_imports(config, components, already_included, session_id, versions, previous_answers = nil, include_all_repeatables = false)
    full_config = []
    full_components = components
    repeatables = []

    config.each do |field|
      if field['include'].nil?
        full_config << field
      else
        included_form = Form.where(:name => field['include'], :session_id => session_id).first
        
        if included_form.nil?
          raise Exceptions::FormNotFoundError.new(field['include'], nil)
        end
        if already_included.include?(included_form.id)
          throw "The form has a circular include of form '#{included_form.name}'"
        end

        included_config, included_components, included_repeatables = included_form.full_configuration(versions, already_included.dup, false)
        if included_config.nil? or included_components.nil? or included_repeatables.nil?
          raise Exceptions::FormNotFoundError.new(field['include'], nil)
        end
        repeatables += included_repeatables
       
        if(field['repeat'].nil?)
          full_config += included_config
        else
          repeatable = Marshal.load(Marshal.dump(included_config))
          repeatable.each do |included_field|
            included_field['id'] = "#{field['repeat']['prefix']}[][#{included_field['id']}]"
          end
          repeatable << {'type' => 'include_divider'}

          repeatables << {:id => field['repeat']['prefix'], :label => field['repeat']['label'], :min => (field['repeat']['min'].nil? ? 0 : field['repeat']['min']), :max => field['repeat']['max'], :config => repeatable}

          full_config << {'type' => 'include_start', 'label' => field['repeat']['label'], 'id' => field['repeat']['prefix'], 'max' => field['repeat']['max']}

          min_repeat = field['repeat']['min']
          if(previous_answers and previous_answers[field['repeat']['prefix']] and previous_answers[field['repeat']['prefix']].respond_to?(:size))
            min_repeat = previous_answers[field['repeat']['prefix']].size if previous_answers[field['repeat']['prefix']].size > min_repeat
          end
          min_repeat = 0 if min_repeat.nil?
          min_repeat = 1 if(min_repeat < 1 and include_all_repeatables == true)
          min_repeat.times do |i|
            config_copy = Marshal.load(Marshal.dump(included_config))
            
            config_copy.each do |included_field|
              included_field['id'] = "#{field['repeat']['prefix']}[#{i}][#{included_field['id']}]"
            end

            config_copy << {'type' => 'include_divider'}

            full_config += config_copy
          end

          full_config << {'type' => 'include_end', 'id' => field['repeat']['prefix']}
        end

        full_components.each do |key, value|
          full_components[key] = value + included_components[key]
        end
      end
    end
    
    return [full_config, full_components, repeatables]
  end

  def include_subforms
    nil
  end
end

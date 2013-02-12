require 'git_config_repository'
require 'schema_validation'

class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description, :name, :session_id, :session, :state, :locked_version

  validates :name, :presence => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }

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
    index = Form::STATE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end

  def form_answers
    return FormAnswer.where(:form_id => self.id)
  end

  def is_template?
    session_id.nil?
  end

  def full_current_configuration
    full_configuration(nil)
  end
  def full_locked_configuration
    full_configuration(self.locked_version)
  end
  def full_configuration_at_version(version)
    full_configuration(version)
  end
  def current_configuration
    parse_config(nil)
  end
  def locked_configuration
    parse_config(self.locked_version)
  end
  def configuration_at_version(versioN)
    parse_config(version)
  end
  def has_configuration?
    File.exists?(self.config_file_path)
  end

  def self.config_field_has_special_type?(field)
    ['add_repeat', 'group-label', 'divider', 'group-end'].include? field['type']
  end

  def relative_config_file_path
    Rails.application.config.form_configs_subdirectory + "/#{id}.yml"
  end
  def config_file_path
    Rails.application.config.form_configs_directory + "/#{id}.yml"
  end

  def included_forms
    config = raw_configuration
    return [] if config.nil?

    return config.reject{|f| f['include'].nil?}.map{|f| f['include'].to_s}
  end

  def semantically_valid?
    return self.validate == []
  end
  def validate
    return nil unless has_configuration?

    validator = SchemaValidation::FormValidator.new
    config = raw_configuration
    return nil if config.nil?

    validation_errors = validator.validate(config)

    included_forms.each do |included_form|
      validation_errors << "Included form '#{included_form}' is missing" if Form.where(:name => included_form, :session_id => self.session_id).empty?
    end

    return validation_errors
  end

  protected
  
  def parse_config(version)
    begin
      config = GitConfigRepository.new.yaml_at_version(relative_config_file_path, version)
    rescue SyntaxError => e
      return nil
    end
    
    return config
  end
  
  # TODO: version is not yet used, since components are not yet versioned
  def components(version)
    id = read_attribute(:id)

    form_components = {:validators => [], :stylesheets => []}

    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.js"))
      form_components[:validators] << File.open(Rails.application.config.form_configs_directory + "/#{id}.js", 'r') {|f| f.read}
    end
    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.css"))
      form_components[:stylesheet] << File.open(Rails.application.config.form_configs_directory + "/#{id}.css", 'r') {|f| f.read}
    end

    return form_components
  end

  def stringify_form_components(components)
    components.each do |key, value|
      components[key] = value.join("\n")
    end
  end

  def full_configuration(version, already_included_forms = nil, stringify = true)
    form_config = parse_config(version)
    return [nil,nil,nil] if form_config.nil?
    form_components = components(version)
    return [nil,nil,nil] if form_components.nil?

    already_included_forms = [] if already_included_forms.nil?
    already_included_forms << read_attribute(:id)

    form_config, form_components, repeatables = process_imports(form_config, form_components, already_included_forms, read_attribute(:session_id), version)
    form_components = stringify_form_components(form_components) if stringify

    return [form_config, form_components, repeatables]
  end
  def process_imports(config, components, already_included, session_id, version)
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

        included_config, included_components, included_repeatables = included_form.full_configuration(version, already_included.dup, false)
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
          repeatable << {'type' => 'divider'}

          repeatables << {:id => field['repeat']['prefix'], :max => field['repeat']['max'], :config => repeatable}

          full_config << {'type' => 'add_repeat', 'group-label' => "#{field['repeat']['label']}s", 'button-label' => "Add #{field['repeat']['label']}", 'id' => field['repeat']['prefix'], 'max' => field['repeat']['max']}

          field['repeat']['min'].times do |i|
            config_copy = Marshal.load(Marshal.dump(included_config))
            
            config_copy.each do |included_field|
              included_field['id'] = "#{field['repeat']['prefix']}[#{i}][#{included_field['id']}]"
            end

            config_copy << {'type' => 'divider'}

            full_config += config_copy
          end

          full_config << {'type' => 'group-end', 'id' => field['repeat']['prefix']}
        end

        full_components.each do |key, value|
          full_components[key] = value + included_components[key]
        end
      end
    end
    
    return [full_config, full_components, repeatables]
  end
end

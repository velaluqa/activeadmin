class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description, :name, :session_id, :session, :state, :locked_version

  validates :name, :presence => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }

  belongs_to :session
  has_many :form_answers

  scope :draft, where(:state => 0)
  scope :final, where(:state => 1)

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

  def is_template?
    session_id == nil
  end

  def configuration(already_included_forms = nil, stringify = true)
    form_config = parse_config
    return [nil,nil,nil] if form_config.nil?
    form_components = components
    return [nil,nil,nil] if form_components.nil?

    already_included_forms = [] if already_included_forms.nil?
    already_included_forms << read_attribute(:id)

    form_config, form_components, repeatables = process_imports(form_config, form_components, already_included_forms, read_attribute(:session_id))
    form_components = stringify_form_components(form_components) if stringify

    return [form_config, form_components, repeatables]
  end
  def raw_configuration
    parse_config
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

  protected
  
  def parse_config
    id = read_attribute(:id)

    begin
      config = YAML.load_file(config_file_path)
    rescue Errno::ENOENT => e
      return nil
    end
    
    return config
  end
  
  def components
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

  def process_imports(config, components, already_included, session_id)
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

        included_config, included_components, included_repeatables = included_form.configuration(already_included.dup, false)
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

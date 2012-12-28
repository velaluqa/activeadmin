class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description
  attr_readonly :name, :form_version

  validates :name, :presence => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }

  belongs_to :session
  has_many :form_answers

  def self.find_with_name_and_version(name, version)
    form = nil

    if version.nil?
      form = Form.where(:name => name).order("form_version DESC").first
    else
      form = Form.where(:name => name, :version => version).first
    end
    
    return form
  end

  def configuration(already_included_forms = nil, stringify = true)
    form_config = parse_config
    return [nil,nil,nil] if form_config.nil?
    form_components = components
    return [nil,nil,nil] if form_components.nil?

    already_included_forms = [] if already_included_forms.nil?
    already_included_forms << read_attribute(:id)

    form_config, form_components, repeatables = process_imports(form_config, form_components, already_included_forms)
    form_components = stringify_form_components(form_components) if stringify

    return [form_config, form_components, repeatables]
  end

  def self.config_field_has_special_type?(field)
    ['add_repeat', 'group-label', 'divider', 'group-end'].include? field['type']
  end

  protected
  
  def parse_config
    id = read_attribute(:id)

    config = YAML.load_file(Rails.application.config.form_configs_directory + "/#{id}.yml")
    
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

  def process_imports(config, components, already_included)
    full_config = []
    full_components = components
    repeatables = []

    config.each do |field|
      if field['include'].nil?
        full_config << field
      else
        included_form = Form.find_with_name_and_version(field['include'], field['version'])
        if included_form.nil?
          throw "The form tried to include form '#{field['include']}', which doesn't exist"
        end
        if already_included.include?(included_form.id)
          throw "The form has a circular include of form '#{included_form.name}'"
        end

        included_config, included_components, included_repeatables = included_form.configuration(already_included, false)
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

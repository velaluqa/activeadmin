require 'yaml'

class FormsController < ApplicationController
  before_filter :find_record
  layout 'client_forms'

  def index
    @forms = Form.all
  end

  def show
    @form_config = parse_form_config(params[:id])
    return if @form_config.nil?
    @form_components = form_components(params[:id])
    return if @form_components.nil?

    @form_config, @form_components = process_imports(@form_config, @form_components, [@form.id])
  end

protected

  def form_by_name(name)
    return Form.where('name = ?', name).first
  end

  def find_record
    begin
      @form = Form.find(params[:id])
    rescue
      flash[:error] = 'Form does not exist'
      redirect_to :action => 'index'
    end
  end

  def parse_form_config(id)
    begin
      config = YAML.load_file(Rails.application.config.form_configs_directory + "/#{id}.yml")
    rescue Errno::ENOENT
      flash[:error] = 'Form configuration for form '#{id}' is missing'
      redirect_to :action => 'index'
    rescue
      flash[:error] = 'Form configuration for form '#{id}' is invalid'
      redirect_to :action => 'index'
    end

    return config
  end

  def form_components(id)
    components = {:validators => [], :stylesheets => []}

    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.js"))
      components[:validators] << File.open(Rails.application.config.form_configs_directory + "/#{id}.js", 'o') {|f| f.read}
    end
    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.css"))
      components[:stylesheet] << File.open(Rails.application.config.form_configs_directory + "/#{id}.css", 'o') {|f| f.read}
    end

    return components
  end

  def process_imports(config, components, already_included)
    full_config = []
    full_components = Hash.new(components)

    config.each do |field|
      if field['include'].nil?
        full_config << field
      else
        included_form = form_by_name(field['include'])
        if included_form.nil?
          flash[:error] = "The form tried to include form '#{field['include']}', which doesn't exist"
          redirect_to :action => 'index'
        end
        if already_included.include?(included_form.id)
          flash[:error] = "The form has a circular include of form '#{included_form.name}'"
          redirect_to :action => 'index'
        end

        already_included << included_form.id

        included_config = parse_form_config(included_form.id)
        included_components = form_components(included_form.id)
        
        included_config, included_components = process_imports(included_config, included_components, already_included)

        full_config += included_config
        full_components.each do |key, value|
          full_components[k] = v + included_components[k]
        end
      end
    end

    full_components.each do |key, value|
      full_components[k] = value.join("\n")
    end    

    return [full_config, full_components]
  end
end

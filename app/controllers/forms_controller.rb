require 'yaml'
require 'pp'


class FormsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_form_from_params, :except => :index
  layout 'client_forms', :only => :show

  def index
    @forms = Form.all
  end

  def show
    @form_config = parse_form_config(@form)
    return if @form_config.nil?
    @form_components = form_components(@form)
    return if @form_components.nil?

    @form_config, @form_components = process_imports(@form_config, @form_components, [@form.id])
    @form_components = stringify_form_components(@form_components)
  end

protected

  def find_form_from_params
    @form = find_form(params[:id], params[:version])
  end
  def find_form(name, version)
    form = nil
    begin
      if version.nil?
        form = Form.find_by_name(name, :order => "version DESC")
      else
        form = Form.find_by_name_and_version(name, version)
      end
      throw "Form does not exist" if form.nil?
    rescue
      flash[:error] = 'Form does not exist'
      redirect_to :action => 'index'
    end

    return form
  end

  def parse_form_config(form)
    begin
      config = YAML.load_file(Rails.application.config.form_configs_directory + "/#{form.id}.yml")
    rescue Errno::ENOENT
      flash[:error] = "Form configuration for form '#{form.id}' (name: #{form.name}, version: #{form.version} ' is missing"
      redirect_to :action => 'index'
    rescue
      flash[:error] = "Form configuration for form '#{form.id}' (name: #{form.name}, version: #{form.version} ' is invalid"
      redirect_to :action => 'index'
    end

    return config
  end

  def form_components(form)
    components = {:validators => [], :stylesheets => []}

    if(File.exists?(Rails.application.config.form_configs_directory + "/#{form.id}.js"))
      components[:validators] << File.open(Rails.application.config.form_configs_directory + "/#{form.id}.js", 'r') {|f| f.read}
    end
    if(File.exists?(Rails.application.config.form_configs_directory + "/#{form.id}.css"))
      components[:stylesheet] << File.open(Rails.application.config.form_configs_directory + "/#{form.id}.css", 'r') {|f| f.read}
    end

    return components
  end

  def stringify_form_components(components)
    components.each do |key, value|
      components[key] = value.join("\n")
    end
  end

  def process_imports(config, components, already_included)
    full_config = []
    full_components = components

    config.each do |field|
      if field['include'].nil?
        full_config << field
      else
        included_form = find_form(field['include'], field['version'])
        if included_form.nil?
          flash[:error] = "The form tried to include form '#{field['include']}', which doesn't exist"
          redirect_to :action => 'index'
        end
        if already_included.include?(included_form.id)
          flash[:error] = "The form has a circular include of form '#{included_form.name}'"
          redirect_to :action => 'index'
        end

        already_included << included_form.id

        included_config = parse_form_config(included_form)
        included_components = form_components(included_form)
        
        included_config, included_components = process_imports(included_config, included_components, already_included)

        full_config += included_config
        full_components.each do |key, value|
          full_components[key] = value + included_components[key]
        end
      end
    end

    return [full_config, full_components]
  end
end

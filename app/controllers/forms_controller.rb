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
    @form_config_components = form_config_components(params[:id])
    return if @form_config_components.nil?
  end

protected

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
      flash[:error] = 'Form configuration is missing'
      redirect_to :action => 'index'
    rescue
      flash[:error] = 'Form configuration is invalid'
      redirect_to :action => 'index'
    end

    return config
  end

  def read_form_config(id)
    begin
      data = File.open() {|f| f.read}
    rescue
      flash[:error] = 'Form configuration is missing'
      redirect_to :action => 'index'
    end

    return data
  end

  def form_config_components(id)
    components = {}

    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.js"))
      components[:validators] = File.open(Rails.application.config.form_configs_directory + "/#{id}.js", 'o') {|f| f.read}
    end
    if(File.exists?(Rails.application.config.form_configs_directory + "/#{id}.css"))
      components[:stylesheet] = File.open(Rails.application.config.form_configs_directory + "/#{id}.css", 'o') {|f| f.read}
    end

    return components
  end
end

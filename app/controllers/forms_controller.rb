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
    @form_config, @form_components, @repeatables = @form.configuration
    
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)
  end

protected

  def find_form_from_params
    @form = Form.find_with_name_and_version(params[:id], params[:version])
  end
end

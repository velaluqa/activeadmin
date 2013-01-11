require 'yaml'
require 'exceptions'

class FormsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_form_from_params, :except => :index
  layout 'client_forms', :only => :show

  def show
    @form_config, @form_components, @repeatables = @form.configuration
    
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)
  end

protected

  def find_form_from_params
    raise Exceptions::CaseNotFoundError.new(params[:case]) if params[:case].nil?

    the_case = Case.find(params[:case])
    raise Exceptions::CaseNotFoundError.new(params[:case]) if the_case.nil?

    if params[:version].nil?
      @form = Form.where(:name => params[:id], :session_id => the_case.session_id).order("form_version DESC").first
    else
      @form = Form.where(:name => params[:id], :session_id => the_case.session_id, :form_version => params[:version]).first
    end

    raise Exceptions::FormNotFoundError.new(params[:id], params[:version], params[:case]) if @form.nil?
  end
end

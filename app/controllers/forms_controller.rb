require 'yaml'
require 'exceptions'

class FormsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_form_from_params, :except => :index
  layout 'client_forms', :only => :show

  def show
    @form_config, @form_components, @repeatables = @form.configuration
    @data_hash = data_hash
    
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)
  end

protected

  def data_hash
    {'patient' => (@case.patient.patient_data.nil? ? {} : @case.patient.patient_data.data), 'case' => (@case.case_data.nil? ? {} : @case.case_data.data)}
  end

  def find_form_from_params
    raise Exceptions::CaseNotFoundError.new(params[:case]) if params[:case].nil?

    @case = Case.find(params[:case])
    raise Exceptions::CaseNotFoundError.new(params[:case]) if @case.nil?

    if params[:version].nil?
      @form = Form.where(:name => params[:id], :session_id => @case.session_id).order("form_version DESC").first
    else
      @form = Form.where(:name => params[:id], :session_id => @case.session_id, :form_version => params[:version]).first
    end

    raise Exceptions::FormNotFoundError.new(params[:id], params[:version], params[:case]) if @form.nil?
  end
end

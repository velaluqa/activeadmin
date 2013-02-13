require 'yaml'
require 'exceptions'

class FormsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_form_from_params, :except => [:index, :preview]
  layout 'client_forms', :only => [:show, :previous_results, :preview]

  def show
    @form_config, @form_components, @repeatables = @form.full_locked_configuration
    @data_hash = @case.data_hash

    if(@case and @case.session)
      configuration = @case.session.locked_configuration

      unless (configuration.nil? or configuration['show_previous_results'].nil? or configuration['show_previous_results'] == false or params[:previous_results].nil? or params[:previous_results] == 'false')
        @previous_cases = construct_previous_cases(configuration['limit_previous_results'])
      end
    end
    
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)
  end

  def previous_results
    if(@case and @case.session)
      configuration = @case.session.locked_configuration

      unless (configuration.nil? or configuration['show_previous_results'].nil? or configuration['show_previous_results'] == false)
        @previous_cases = construct_previous_cases(configuration['limit_previous_results'])
      end
    end
  end

  def preview
    @form = Form.find(params[:id])
    authorize! :read, @form

    @form_config, @form_components, @repeatables = @form.full_locked_configuration   
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)

    patient = Patient.new
    patient.session = @form.session
    patient.subject_id = 'preview'

    @case = Case.new
    @case.images = 'preview'
    @case.position = 0
    @case.case_type = 'preview'
    @case.session = @form.session
    @case.patient = patient

    render :show
  end

protected

  def construct_previous_cases(enabled_case_types = nil)
    previous_cases_list = @case.patient.cases.where('position < ?', @case.position).reject {|c| c.form_answer.nil?}
    
    previous_cases = {}
    previous_cases_list.each do |c|
      next unless (enabled_case_types.nil? or enabled_case_types.include?(c.case_type))
      if(previous_cases[c.case_type].nil?)
        previous_cases[c.case_type] = []
      end
      
      previous_cases[c.case_type] << c
    end
    
    return previous_cases
  end

  def authorize_user_for_case
    raise CanCan::AccessDenied.new('You are not authorized to access this case!', :read, @case) unless (@case.session.readers.include?(current_user) or
                                                                                                        @case.session.validators.include?(current_user))
  end

  def find_form_from_params
    raise Exceptions::CaseNotFoundError.new(params[:case]) if params[:case].nil?

    @case = Case.find(params[:case])
    raise Exceptions::CaseNotFoundError.new(params[:case]) if @case.nil?

    @form = Form.where(:name => params[:id], :session_id => @case.session_id).first

    raise Exceptions::FormNotFoundError.new(params[:id], params[:case]) if @form.nil?

    authorize_user_for_case
  end
end

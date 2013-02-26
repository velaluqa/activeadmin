require 'yaml'
require 'exceptions'

class FormsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_form_from_params, :except => [:index, :preview]
  layout 'client_forms', :only => [:show, :previous_results, :preview]

  def show
    @form_config, @form_components, @repeatables = @form.full_locked_configuration
    @data_hash = @case.data_hash

    setup_previous_cases_config
    @previous_results = construct_previous_results_list
    
    return if (@form_config.nil? or @form_components.nil? or @repeatables.nil?)
  end

  def previous_results
    setup_previous_cases_config
  end

  def preview
    @form = Form.find(params[:id])
    authorize! :read, @form

    @form_config, @form_components, @repeatables = @form.full_current_configuration
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

  def setup_previous_cases_config
    if(@case and @case.session)
      configuration = @case.session.locked_configuration

      unless (configuration.nil? or configuration['types'].nil? or configuration['types'][@case.case_type].nil? or configuration['types'][@case.case_type]['previous_results'].nil?)
        previous_results_config = configuration['types'][@case.case_type]['previous_results']

        if(previous_results_config['default_table'] == true)
          @table_type = :default
          @previous_cases = construct_previous_cases
        elsif(previous_results_config['table'])
          @table_type = :custom
          @table_config = previous_results_config['table']
          @merge_table_columns = previous_results_config['merge_columns']
          @previous_cases = @case.patient.cases.where('position < ?', @case.position).reject {|c| c.form_answer.nil?}
        end
      end
    end
  end
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
  def construct_previous_results_list
    previous_cases = @case.patient.cases.where('position < ?', @case.position).reject {|c| c.form_answer.nil?}

    previous_results = []
    previous_cases.each do |c|
      previous_results << {'answers' => c.form_answer.answers, 'images' => c.images}
    end
    previous_results << {'images' => @case.images}

    return previous_results
  end

  def authorize_user_for_case
    raise CanCan::AccessDenied.new('You are not authorized to access this case!', :read, @case) unless ((@case.session.state == :production and @case.session.readers.include?(current_user)) or
                                                                                                        (@case.session.state == :testing and @case.session.validators.include?(current_user)))
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

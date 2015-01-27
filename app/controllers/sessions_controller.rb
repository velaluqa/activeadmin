class SessionsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_session, :except => :list

  def show
    config = @session.locked_configuration

    if config.nil?
      result = { :error_code => 1, :error => "Session is not configured"}
    else
      result = {:session => @session, :configuration => config}
    end

    respond_to do |format|
      format.json { render :json => result }
    end
  end

  def list
    blind_readable = current_user.blind_readable_sessions
      .reject {|s| s.state != :production}
      .reject {|s| s.case_list(:unread).reject {|c| c.assigned_reader and c.assigned_reader != current_user}.empty? and s.case_list(:reopened).reject {|c| c.form_answer.nil? or c.form_answer.user != current_user }.empty?}
      .map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    validatable = current_user.validatable_sessions
      .reject {|s| s.state != :testing}
      .reject {|s| s.case_list(:unread).reject {|c| c.assigned_reader and c.assigned_reader != current_user}.empty? and s.case_list(:reopened).reject {|c| c.form_answer.nil? or c.form_answer.user != current_user }.empty?}
      .map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    respond_to do |format|
      format.json { render :json => {'Blinded Read' => blind_readable, 'Validation' => validatable} }
    end
  end

  def reserve_cases
    count = (params[:count].nil? ? 1 : params[:count].to_i)

    config = @session.locked_configuration
    if config.nil?
      render :json => { :error_code => 1, :error => "Session is not configured"}, :status => :bad_request
      return
    end

    cases = []

    if(@reopened_cases.empty?)
      last_reader_testing_result = current_user.test_results_for_session(@session).last
      if(config['reader_testing'] and (last_reader_testing_result.nil? or last_reader_testing_result.submitted_at < Time.now - config['reader_testing']['interval'] or last_reader_testing_result.run_form_judgement_function() != true) and session[:reader_testing_performed] != true)
        cases << create_reader_test_case(config, (last_reader_testing_result.nil? ? nil : last_reader_testing_result.reader_testing_config_index))
        count -= 1
        session[:reader_testing_performed] = true
      end

      session[:min_reserved_case_position] ||= 0

      count.times do |i|
        c = @session.reserve_next_case_for_reader(session[:min_reserved_case_position]+i, current_user)
        break if c.nil?

        cases << c

        c.current_reader = current_user

        if(config['auto_assign_patients_to_readers'] == true and c.assigned_reader.nil? and c.patient)
          cases_to_assign = c.patient.cases.where(:state => Case::state_sym_to_int(:unread), :assigned_reader_id => nil, :flag => Case::flag_sym_to_int(c.flag))

          cases_to_assign.each do |case_to_assign|
            case_to_assign.assigned_reader = current_user
            case_to_assign.save
          end

          c.assigned_reader = current_user
          c.save
        end

        c.save
      end

      session[:min_reserved_case_position] = cases.last.position+1 unless cases.empty?
    else
      @reopened_cases.each do |c|
        break if cases.size > count

        c.state = :reopened_in_progress
        c.current_reader = current_user
        c.save

        cases << c
      end
    end

    passive_cases = passive_cases_for_case_list(cases)

    case_hashes = cases.map do |c|
      case_hash = c.to_hash.merge({:passive_cases => passive_cases[c.id]})
      if(config['type'] == 'adjudication' and c.case_data and c.case_data.adjudication_data)
        adjudication_annotation_sets = prepare_adjudication_annotation_sets(c, config)
        case_hash.merge!({:adjudication_annotation_sets => adjudication_annotation_sets}) unless adjudication_annotation_sets.nil?

        case_hash[:passive_cases].each do |pc|
          pc_adjudication_annotation_sets = prepare_adjudication_annotation_sets(Case.find(pc[:id]), config)
          pc.merge!({:adjudication_annotation_sets => pc_adjudication_annotation_sets}) unless pc_adjudication_annotation_sets.nil?
        end
      end

      case_hash
    end
    pp case_hashes

    respond_to do |format|
      format.json { render :json => {:cases => case_hashes} }
    end
  end

  protected

  def prepare_adjudication_annotation_sets(c, config)
    return nil unless (c.case_data and c.case_data.adjudication_data)

    adjudication_assignment = c.case_data.adjudication_data['assignment']

    adjudication_annotation_sets = []

    config['adjudication']['sessions'].each_with_index do |session_id, index|
      base_session = Session.find(session_id)

      annotated_images_root = (base_session.state == :testing and base_session.locked_configuration['annotated_images_root_validation']) ? base_session.locked_configuration['annotated_images_root_validation'] : base_session.locked_configuration['annotated_images_root']
      assignment = adjudication_assignment[index].to_i - 1

      annotation_set = {:path => annotated_images_root + '/' + c.images_folder, :color => config['adjudication']['colors'][assignment], :name => "Reader #{assignment+1}: "}

      adjudication_annotation_sets << annotation_set
    end

    return adjudication_annotation_sets
  end

  def create_reader_test_case(config, last_config_index)
    reader_testing_configs = config['reader_testing']['configs']
    reader_testing_configs ||= [config['reader_testing']]
    return nil if reader_testing_configs.blank?

    config_index = (last_config_index.nil? ? 0 : (last_config_index + 1) % reader_testing_configs.size)
    reader_testing_config = reader_testing_configs[config_index]
    return nil if reader_testing_config.nil?

    patient = Patient.where(:subject_id => reader_testing_config['patient'], :session_id => @session.id).first
    return nil if patient.nil?

    test_case = Case.create(:session_id => @session.id, :patient_id => patient.id, :position => @session.next_position, :images => reader_testing_config['images'], :case_type => reader_testing_config['case_type'], :state => :in_progress, :flag => :reader_testing, :assigned_reader_id => current_user.id, :current_reader_id => current_user.id)
    return nil unless test_case.persisted?

    test_case_answer = FormAnswer.create(:user_id => current_user.id, :session_id => @session.id, :case_id => test_case.id, :submitted_at => Time.now, :reader_testing_config_index => config_index)

    return test_case
  end

  def authorize_user_for_session
    raise CanCan::AccessDenied.new('You are not authorized to access this session!', :read, @session) unless ((@session.state == :production and @session.readers.include?(current_user)) or
                                                                                                              (@session.state == :testing and @session.validators.include?(current_user)))
  end
  def find_session
    begin
      @session = Session.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'Session not found', :error_code => 1}
      return false
    end

    authorize_user_for_session
    check_for_reopened_cases
  end
  def check_for_reopened_cases
    @reopened_cases = @session.cases.where(:state => Case::state_sym_to_int(:reopened))
      .reject {|c| c.form_answer.nil? }
      .reject {|c| c.form_answer.user != current_user }
  end

  def passive_cases_for_case_list(case_list)
    imported = []
    passive_cases = {}

    case_list.each do |c|
      previous_cases = c.patient.cases.where('position < ?', c.position)

      imported << c.id

      passive_cases[c.id] = []
      previous_cases.each do |pc|
        next if imported.include?(pc.id)

        imported << pc.id
        passive_cases[c.id] << pc.to_hash
      end
    end

    return passive_cases
  end
end

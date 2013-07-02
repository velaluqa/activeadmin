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
      .reject {|s| s.case_list(:unread).empty? and s.case_list(:reopened).reject {|c| c.form_answer.nil? or c.form_answer.user != current_user }.empty?}
      .map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    validatable = current_user.validatable_sessions
      .reject {|s| s.state != :testing}
      .reject {|s| s.case_list(:unread).empty? and s.case_list(:reopened).reject {|c| c.form_answer.nil? or c.form_answer.user != current_user }.empty?}
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
      if(config['reader_testing'] and (last_reader_testing_result.nil? or last_reader_testing_result.submitted_at < Time.now - config['reader_testing']['interval']))
        cases << create_reader_test_case(config)
        count -= 1
      end

      session[:min_reserved_case_position] ||= 0

      count.times do |i|
        c = @session.reserve_next_case_for_reader(session[:min_reserved_case_position]+i, current_user)
        break if c.nil?

        cases << c

        c.current_reader = current_user
        c.save
      end

      session[:min_reserved_case_position] = cases.last.position+1 unless cases.empty?
    else
      @reopened_cases.each do |c|
        c.state = :reopened_in_progress
        c.current_reader = current_user
        c.save

        cases << c
      end
    end

    passive_cases = passive_cases_for_case_list(cases)

    case_hashes = cases.map do |c|
      c.to_hash.merge({:passive_cases => passive_cases[c.id]})
    end

    respond_to do |format|
      format.json { render :json => {:cases => case_hashes} }
    end    
  end

  protected

  def create_reader_test_case(config)
    patient = Patient.where(:subject_id => config['reader_testing']['patient'], :session_id => @session.id).first
    return nil if patient.nil?

    test_case = Case.create(:session_id => @session.id, :patient_id => patient.id, :position => @session.next_position, :images => config['reader_testing']['images'], :case_type => config['reader_testing']['case_type'], :state => :in_progress, :flag => :reader_testing)
    return nil unless test_case.persisted?

    test_case_answer = FormAnswer.create(:user_id => current_user.id, :session_id => @session.id, :case_id => test_case.id, :submitted_at => Time.now)

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

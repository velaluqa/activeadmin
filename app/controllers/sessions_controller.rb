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
      .reject {|s| s.case_list(:unread).empty?}
      .map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    validatable = current_user.validatable_sessions
      .reject {|s| s.state != :testing}
      .reject {|s| s.case_list(:unread).empty?}
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

    last_reader_testing_result = current_user.test_results_for_session(@session).last
    if(config['reader_testing'] and (last_reader_testing_result.nil? or last_reader_testing_result.submitted_at < Time.now - config['reader_testing']['interval']))
      cases << create_reader_test_case(config)
      count -= 1
    end

    count.times do
      c = @session.reserve_next_case
      break if c.nil?
      cases << c
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

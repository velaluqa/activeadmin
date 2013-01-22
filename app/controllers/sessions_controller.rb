class SessionsController < ApplicationController
  before_filter :authenticate_user!

  def show
    begin
      @session = Session.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'Session not found'}
      return
    end

    authorize! :read, @session

    full_sequence = (params[:full_sequence] == 'true')
    case_list = @session.case_list(full_sequence ? :all : :unread)

    passive_cases = passive_cases_for_case_list(case_list)

    case_list_hashes = case_list.map do |c|
      c.to_hash.merge({:passive_cases => passive_cases[c.id]})
    end

    config = @session.configuration
    next_case = @session.next_unread_case
    
    if config.nil?
      result = { :error_code => 1, :error => "Session is not configured"}
    else
      result = {:session => @session, :configuration => @session.configuration, :case_list => case_list_hashes, :next_case_position => (next_case.nil? ? 0 : next_case.position)}
    end
    
    respond_to do |format|
      format.json { render :json => result }
    end      
  end

  def blind_readable
    @sessions = current_user.blind_readable_sessions.reject {|s| s.case_list(:unread).empty?}.map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    respond_to do |format|
      format.json { render :json => {:sessions => @sessions} }
    end
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

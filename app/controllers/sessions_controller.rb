class SessionsController < ApplicationController
  before_filter :authenticate_user!

  def show
    begin
      @session = Session.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'Session not found'}
      return
    end

    full_sequence = (params[:full_sequence] == 'true')
    case_list = @session.case_list(full_sequence ? :all : :unread)

    case_list_hashes = case_list.map do |c|
      {
        :images => c.images,
        :images_folder => c.images_folder,
        :position => c.position,
        :id => c.id,
        :case_type => c.case_type,
        :patient_id => c.patient_id,
      }
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
    @sessions = Session.blind_readable_by_user(current_user).map {|s| {:name => s.name, :id => s.id, :study_name => s.study.name} }

    respond_to do |format|
      format.json { render :json => {:sessions => @sessions} }
    end
  end  
end

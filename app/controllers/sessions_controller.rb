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
    view_sequence = @session.view_sequence(!full_sequence)

    result = {:session => @session, :configuration => @session.configuration, :view_sequence => view_sequence, :current_sequence_row => @session.current_sequence_row}
    
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

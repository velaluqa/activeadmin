class SessionsController < ApplicationController
  before_filter :authenticate_user!

  def show
    begin
      @session = Session.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render :json => {:error => 'Session not found'}
      return
    end
    
    respond_to do |format|
      format.json { render :json => @session }
    end      
  end

  def blind_readable
    @sessions = Session.blind_readable_by_user(current_user)

    respond_to do |format|
      format.json { render :json => @sessions }
    end
  end  
end

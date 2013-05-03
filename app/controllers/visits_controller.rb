class VisitsController < ApplicationController
  before_filter :load_the_visit, :only => [:wado_query]

  def wado_query
    @patients = [{:name => @visit.patient.name, :visits => [@visit.wado_query]}]

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  protected

  def load_the_visit
    @visit = Visit.find(params[:id])
    authorize! :manage, @visit
  end
end

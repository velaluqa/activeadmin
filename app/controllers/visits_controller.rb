class VisitsController < ApplicationController
  before_action :load_the_visit, only: %i[wado_query required_series_wado_query]

  def wado_query
    @patients = [{ id: @visit.patient.id, name: @visit.patient.name, visits: [@visit.wado_query] }]

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  def required_series_wado_query
    @patients = [{ id: @visit.patient.id, name: @visit.patient.name, visits: [@visit.required_series_wado_query] }]

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  protected

  def load_the_visit
    @visit = Visit.find(params[:id])
    authorize! :read, @visit
  end
end

class PatientsController < ApplicationController
  before_filter :load_patients

  def index
    respond_to do |format|
      format.json { render :json => @patients}
    end
  end

  protected

  def load_patients
    @center = Center.find(params[:center_id])
    authorize! :read, @center

    authorize! :read, Patient
    @patients = @center.patients.accessible_by(current_ability)
  end
end

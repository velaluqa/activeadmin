class PatientsController < ApplicationController
  before_filter :load_center
  before_filter :load_patients, :only => :index

  def index
    respond_to do |format|
      format.json { render :json => @patients}
    end
  end

  def create
    authorize! :create, Patient

    patient = Patient.create(:subject_id => params[:patient][:subject_id], :center => @center)
    
    respond_to do |format|
      format.json { render :json => {:success => !patient.nil?, :patient => patient} }
    end    
  end

  protected

  def load_center
    @center = Center.find(params[:center_id])
    authorize! :read, @center
  end

  def load_patients
    authorize! :read, Patient
    @patients = @center.patients.accessible_by(current_ability)
  end
end

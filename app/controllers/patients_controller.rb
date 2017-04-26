class PatientsController < ApplicationController
  before_filter :load_center, :only => [:index, :create]
  before_filter :load_patients, :only => [:index]
  before_filter :load_the_patient, :only => [:wado_query]

  skip_before_filter :verify_authenticity_token, :only => [:create]

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

  def wado_query
    @patients = [@patient.wado_query]

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
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

  def load_the_patient
    @patient = Patient.find(params[:id])
    authorize! :manage, @patient
  end
end

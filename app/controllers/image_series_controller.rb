class ImageSeriesController < ApplicationController
  before_filter :load_patient, :only => [:index, :create]
  before_filter :load_image_series, :only => :index
  before_filter :load_the_image_series, :only => [:wado_query]

  skip_before_filter :verify_authenticity_token, :only => [:create]

  def index
    respond_to do |format|
      format.json { render :json => @image_series}
    end
  end

  def create
    authorize! :create, ImageSeries

    image_series = ImageSeries.create(:name => params[:image_series][:name], :patient => @patient, :visit_id => nil, :imaging_date => params[:image_series][:imaging_date], :state => :imported)

    respond_to do |format|
      format.json { render :json => {:success => !image_series.nil?, :image_series => image_series} }
    end
  end

  def wado_query
    visit_name = (@image_series.visit.nil? ? 'Unassigned' : "Visit No. #{@image_series.visit.visit_number}""Visit No. #{@image_series.visit.visit_number}")
    visit_id = (@image_series.visit.nil? ? 0 : @image_series.visit.id)

    @patients = [{:id => @image_series.patient.id, :name => @image_series.patient.name, :visits =>
                   [{:id => visit_id, :name => visit_name, :image_series => [@image_series.wado_query]}]
                 }]

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  protected

  def load_patient
    @patient = Patient.find(params[:patient_id])
    authorize! :read, @patient
  end

  def load_image_series
    authorize! :read, ImageSeries
    @image_series = @patient.image_series.accessible_by(current_ability)
  end
  def load_the_image_series
    @image_series = ImageSeries.find(params[:id])
    authorize! :read, @image_series
  end
end

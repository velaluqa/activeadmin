class ImageSeriesController < ApplicationController
  before_filter :load_patient
  before_filter :load_image_series, :only => :index

  skip_before_filter :verify_authenticity_token, :only => [:create]

  def index
    respond_to do |format|
      format.json { render :json => @image_series}
    end
  end

  def create
    authorize! :create, ImageSeries

    image_series = ImageSeries.create(:name => params[:image_series][:name], :patient => @patient, :visit_id => nil)
    
    respond_to do |format|
      format.json { render :json => {:success => !image_series.nil?, :image_series => image_series} }
    end
  end

  protected

  def load_patient
    @patient = Patient.find(params[:patient_id])
    authorize! :read, @patient
  end

  def load_image_series
    authorize! :read, ImageSeries
    @image_series = @patient.image_series.aaccessible_by(current_ability)
  end
end

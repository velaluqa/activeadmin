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

    image_series = ImageSeries.create(:name => params[:image_series][:name], :patient => @patient, :visit_id => nil, :imaging_date => params[:image_series][:imaging_date])
    
    respond_to do |format|
      format.json { render :json => {:success => !image_series.nil?, :image_series => image_series} }
    end
  end

  def wado_query
    @images = @image_series.images.order('id ASC')

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml
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
    #authorize! :manage, @image_series
  end
end

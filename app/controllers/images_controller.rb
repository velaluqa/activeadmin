class ImagesController < ApplicationController
  before_filter :load_image_series

  def create
    authorize! :create, Image

    image = Image.create(:image_series => @image_series)
    
    respond_to do |format|
      format.json { render :json => {:success => !image.nil?, :image => image} }
    end
  end
  def batch_create
    authorize! :create, Image

    count = params[:count]
    
    image_paths = []

    count.times do
      image = Image.create(:image_series => @image_series)
      image_paths << image.image_storage_path unless image.nil?
    end
    
    respond_to do |format|
      format.json { render :json => {:success => (image_paths.size == count), :image_paths => image_paths} }
    end
  end

  protected

  def load_image_series
    @image_series = ImageSeries.find(params[:image_series_id])
    authorize! :read, @image_series
  end
end

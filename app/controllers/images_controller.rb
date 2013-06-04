class ImagesController < ApplicationController
  before_filter :load_image_series

  skip_before_filter :verify_authenticity_token, :only => [:create]

  def create
    authorize! :create, Image

    if(@image_series.nil? or params[:file].blank?)
      respond_to do |format|
        format.json { render :json => {:success => false, :error_code => 1, :error => 'Missing parameters.'}, :status => :bad_request }
      end
      return
    end

    image = Image.create(:image_series => @image_series)
    unless(image.nil?)
      begin
        File.open(image.absolute_image_storage_path, 'w') do |target_file|
          target_file.write(params[:file].read)
        end
      rescue Exception => e
        image.destroy

        respond_to do |format|
          format.json { render :json => {:success => false, :error_code => 2, :error => 'Failed to write the uploaded file to the image storage.'}, :status => :internal_server_error }
        end
      end
    end
    
    respond_to do |format|
      format.json { render :json => {:success => (not image.nil? and image.file_is_present?), :image => image} }
    end
  end

  protected

  def load_image_series
    @image_series = ImageSeries.find(params[:image_series_id])
    authorize! :read, @image_series
  end
end

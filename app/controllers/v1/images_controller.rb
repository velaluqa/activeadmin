class V1::ImagesController < V1::ApiController
  def create
    authorize! :create, Image

    @image = Image.new(image_params)

    respond_to do |format|
      format.json do
        unless @image.save
          render json: { errors: @image.errors.full_messages }, status: :unprocessable_entity
          return
        end
        begin
          @image.write_anonymized_file(image_params[:file][:data].read)
        rescue StandardError => e
          @image.destroy
          Rails.logger.error "Failed to write uploaded image to image storage: #{e.message}"
          e.backtrace.each { |line| Rails.logger.error(line) }
          render json: { errors: ["Failed to write uploaded file to the image storage: #{e.message}"] }, status: :internal_server_error
          return
        end
        render json: @image.to_json, status: :created
      end
    end
  end

  protected

  def image_params
    params.require(:image).permit(:image_series_id, file: [:name, :data])
  end
end

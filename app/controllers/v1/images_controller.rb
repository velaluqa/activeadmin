class V1::ImagesController < V1::ApiController
  def show
    image = Image.find(params[:id])
    ap image.dicom_metadata
    send_file image.absolute_image_storage_path, status: :ok, type: 'application/dicom'
  end

  def create
    authorize_combination! [:create, Image], [:upload, ImageSeries]

    @image = Image.new(image_params)

    respond_to do |format|
      format.json do
        unless @image.save
          render json: { errors: @image.errors.full_messages }, status: :unprocessable_entity
          return
        end
        begin
          @image.write_anonymized_file(file_params[:file][:data])
          if DICOM::FileUtils.multi_frame?(@image.absolute_image_storage_path)
            SplitMultiFrameDicomWorker.perform_async(
              @image.id,
              name: "Split multi-frame DICOM upload #{@image.image_series.name}",
              user_id: current_user.id
            )
          end
          render json: @image.to_json, status: :created
        rescue StandardError => image_error
          begin
            @image.save_error_file(file_params[:file][:data])
          rescue StandardError => backup_error 
            Rails.logger.error "Failed to write backup file: #{backup_error.message}"
          ensure
            @image.destroy
            Rails.logger.error "Failed to write uploaded image to image storage: #{image_error.message}"
            image_error.backtrace.each { |line| Rails.logger.error(line) }
            render(
              json: {
                errors: ["Error writing file to the image storage: #{image_error.message}"] 
              }, 
              status: :internal_server_error
            )
          end
        end
      end
    end
  end

protected

  def image_params
    params.require(:image).permit(:image_series_id)
  end

  def file_params
    params.require(:image).permit(file: %i[name data])
  end
end

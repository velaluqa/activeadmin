module V1
  class ImageSeriesController < V1::ApiController
    def create
      authorize_one! [:create, :upload], ImageSeries

      series_params = image_series_params
      series_params[:state] = :importing unless series_params[:state]

      @series = ImageSeries.new(series_params)

      respond_to do |format|
        format.json do
          if @series.save
            render json: @series.to_json, status: :created
          else
            render json: { errors: @series.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end

    def update
      @series = ImageSeries.find(params[:id])

      authorize_one! [:update, :upload], ImageSeries

      @series.assign_attributes(image_series_params)

      respond_to do |format|
        format.json do
          if @series.save
            render json: { status: :ok }, status: :ok
          else
            render json: { errors: @series.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end

    def finish_import
      @series = ImageSeries.find(params[:id])
      authorize! :upload, ImageSeries

      unless params[:expected_image_count]
        render json: { errors: ["Parameter `expected_image_count` missing."] },
               status: :bad_request
        return
      end

      if expected_image_count != @series.images.count
        render json: { errors: ["Could not finish import. Expected #{expected_image_count} images, server got #{@series.images.count}."] },
               status: :conflict
        return
      end

      @series.update_attribute(:state, :imported)
      render json: {}, status: :ok
    end

    def assign_required_series
      @series = ImageSeries.find(params[:id])

      authorize! :assign_required_series, @series.visit

      unless @series.visit
        render json: { errors: ['Resource does not have a visit associated.'] },
               status: :method_not_allowed
        return
      end

      @series.change_required_series_assignment(params[:required_series])

      render json: { status: :ok }, status: :ok
    end

    protected

    def image_series_params
      params
        .require(:image_series)
        .permit(:name, :series_number, :patient_id, :imaging_date, :visit_id, :state)
    end

    def expected_image_count
      params[:expected_image_count].to_i
    rescue
      -1
    end
  end
end

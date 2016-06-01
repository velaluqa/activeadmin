module V1
  class ImageSeriesController < V1::ApiController
    def create
      authorize! :create, ImageSeries

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
      authorize! :update, ImageSeries

      @series = ImageSeries.find(params[:id])
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
  end
end

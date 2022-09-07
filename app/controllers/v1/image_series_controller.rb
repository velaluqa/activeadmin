module V1
  class ImageSeriesController < V1::ApiController
    def viewer
      series_instance_uid = nil
      study_instance_uid = nil

      image_series = ImageSeries.find(params[:id])
      instances = image_series.images.map do |image|
        meta = image.dicom_metadata[1]

        series_instance_uid ||= meta["0020,000e"].andand[:value]
        study_instance_uid ||= meta["0020,000d"].andand[:value]
        sop_instance_uid = meta["0008,0018"].andand[:value]

        {
          "metadata": {
                        "Columns": image.dicom_metadata[1]["0028,0011"][:value].to_i,
                       "Rows": image.dicom_metadata[1]["0028,0010"][:value].to_i,
                       "InstanceNumber": image.dicom_metadata[1]["0020,0013"][:value].to_i,
                       "AcquisitionNumber": meta["0020,0012"][:value].to_i,
                       "PhotometricInterpretation": meta["0028,0004"][:value],
                       "BitsAllocated": meta["0028,0100"][:value].to_i,
                       "BitsStored": meta["0028,0100"][:value].to_i,
                       "PixelRepresentation": meta["0028,0103"][:value].to_i,
                       "SamplesPerPixel": meta["0028,0002"][:value].to_i,
                       "PixelSpacing": meta["0028,0030"].andand[:value].to_f,
                       "HighBit": meta["0028,0102"][:value].to_i,
                       # "ImageOrientationPatient": meta["0020,0037"].andand[:value],
                       # "ImagePositionPatient": meta["0020,0032"].andand[:value],
                       "FrameOfReferenceUID": meta["0020,0052"].andand[:value],
                       "ImageType": meta["0008,0008"].andand[:value].split('\\'),
                       "Modality": meta["0008,0060"].andand[:value],
                       "SOPInstanceUID": sop_instance_uid,
                       "SeriesInstanceUID": series_instance_uid,
                       "StudyInstanceUID": study_instance_uid
                      },
         "url": "dicomweb://localhost:3000/v1/images/#{image.id}"
        }
      end
      render json: {
               "studies": [
                            {
                              "StudyInstanceUID": study_instance_uid,
                             "StudyDescription": "BRAIN SELLA",
                             "StudyDate": "20010108",
                             "StudyTime": "120022",
                             "PatientName": "MISTER^MR",
                             "PatientId": "832040",
                             "series": [
                                         {
                                           "SeriesDescription": "SAG T-1",
                                          "SeriesInstanceUID": series_instance_uid,
                                          "SeriesNumber": 2,
                                          "SeriesDate": "20010108",
                                          "SeriesTime": "120318",
                                          "Modality": "MR",
                                          "instances": instances
                                         }
                                       ]
                            }
                          ]
             }
    end

    def create
      authorize_one! %i[create upload], ImageSeries

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

      authorize_one! %i[update upload], ImageSeries

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
        render json: { errors: ['Parameter `expected_image_count` missing.'] },
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

class QidoController < ApplicationController
  ALLOWED_CART_ITEMS = [:image_series, :visit, :patient, :center, :study]

  layout nil

  def query_studies
    render json: fetch_json(scoped_patients, cache_base: "patients")
  end

  def query_series
    render json: fetch_json(scoped_series, cache_base: "image_series")
  end

  def query_instances
    # TODO: filter tags in fetch_json
    tags = [
      '00080016', # sop class uid
      '00080018'  # sop instance uid
    ]

    images = Image.dicom.where(image_series_id: mapped_params[:series_id])

    render json: fetch_json(images, cache_base: "images")
  end

  def query_metadata
    images = Image.dicom.where(image_series_id: mapped_params[:series_id])

    render json: fetch_json(images, cache_base: "images")
  end

  def query_frame
    image = Image.find(mapped_params[:image_id])
    dicom = image.dicom

    content_id = SecureRandom.hex(8)
    boundary = SecureRandom.hex(8)
    term = "\r\n"
    content_type = "multipart/related;start=#{content_id};type=\"application/octet-stream\";boundary='#{boundary}'"

    buffer = StringIO.new
    buffer.print("--#{boundary}#{term}");
    buffer.print("Content-Location: #{request.url}#{term}");
    buffer.print("Content-ID: #{content_id}#{term}");
    buffer.print("Content-Type: application/octet-stream#{term}");
    buffer.print(term);
    buffer.print(dicom.image_strings[mapped_params[:frame_number] - 1])

    buffer.print("#{term}--#{boundary}--#{term}");

    send_data(buffer.string, type: content_type)
  end

  def mapped_params
    @mapped_params ||= {
      study_id: params[:study_uid]&.slice(PREFIX_LENGTH..-1).to_i,
      series_id: params[:series_uid]&.slice(PREFIX_LENGTH..-1).to_i,
      image_id: params[:instance_uid]&.slice(PREFIX_LENGTH..-1).to_i,
      frame_number: params[:frame_number]&.to_i || 0
    }
  end

  def scoped_patients
    ap params[:scope]
    ap params[:scope_id]
    if scope == "patient"
      Patient.where(id: scope_id)
    elsif scope == "image_series"
      Patient.where(id: ImageSeries.find(scope_id).patient_id)
    end
  end

  def scoped_series
    ap params[:scope]
    ap params[:scope_id]
    if scope == "image_series"
      ImageSeries
        .with_dicom
        .where(id: scope_id)
        .where(patient_id: mapped_params[:study_id])

    elsif scope == "patient"
      ImageSeries
        .with_dicom
        .where(patient_id: scope_id)

    elsif scope == "visit"
      query = JSON.parse(Base64.decode64(params[:scope_id])).symbolize_keys
      visit_id = query[:visit_id]
      series = query[:series]

      if series == "all_rs"
        ImageSeries
          .with_dicom
          .joins(:required_series)
          .where('required_series.visit_id = ?', query[:visit_id])
      elsif series == "all"
        ImageSeries
          .with_dicom
          .where(visit_id: visit_id)
      else
        ImageSeries
          .with_dicom
          .joins(:required_series)
          .where('required_series.visit_id = ?', query[:visit_id])
          .where('required_series.name = ?', series)
      end
    elsif scope == "viewer_cart"
      groups =
        (session[:viewer_cart] || [])
          .group_by { |item| item[:type] }
          .transform_values { |group| group.map { |item| item[:id] } }

      q = ImageSeries
        .with_dicom
        .joins(:visit, patient: { center: :study })

      queries = []
      groups.slice(*ALLOWED_CART_ITEMS).each_pair do |key, ids|
        queries << q.where("#{key.to_s.pluralize}.id IN (?)", ids)
      end
      queries.reduce(:or)
    elsif scope == "form_answer"
      # TODO: Add display type related filters here
      form_answer = FormAnswer.find(scope_id)
      groups = form_answer
        .form_answer_resources
        .pluck(:resource_type, :resource_id)
        .group_by(&:first)
        .transform_keys(&:downcase)
        .transform_values { |group| group.map(&:last) }

      q = ImageSeries
            .with_dicom
            .joins(:visit, patient: { center: :study })
      queries = []
      groups.each_pair do |key, ids|
        queries << q.where("#{key.to_s.pluralize}.id IN (?)", ids)
      end
      queries.reduce(:or)
    else
      fail "Unknown viewer end-point scope: #{scope}"
    end
  end

  def scoped_images
    ap params[:scope]
    ap params[:scope_id]
  end

  def scope
    params[:scope]
  end

  def scope_id
    params[:scope_id]
  end

  def fetch_json(relation, cache_base:)
    sub_query =
      relation
        .select("#{cache_base}.cache -> 'dicomwebMetadata' AS dicomwebMetadata")
        .where("#{cache_base}.cache ->> 'dicomwebMetadata' != 'null'")
    ImageSeries
      .connection
      .execute("SELECT array_to_json(array_agg(dicomwebMetadata)) AS json FROM (#{sub_query.to_sql}) AS metadata")
      .first["json"]
  end

  PREFIX_LENGTH = Rails.application.config.wado_dicom_prefix.length
end

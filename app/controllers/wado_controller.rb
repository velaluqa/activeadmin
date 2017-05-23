# -*- coding: utf-8 -*-
class WadoController < ApplicationController
  before_filter :skip_trackable # do not track requests to the WADO API as logins/logouts, because every single request would be counted as one login
  before_filter :authenticate_user!
  before_filter :authorize_user!

  before_filter :check_request_type

  before_filter :read_wado_parameters
  before_filter :parse_transfer_syntax
  before_filter :find_supported_content_type
  before_filter :find_image

  # we only support single/multi-frame dicom images as objects

  def wado
    if(@wado_request[:chosen_content_type] == 'application/dicom')
      begin
        converted_image = image_to_transfer_syntax(@wado_request[:transfer_syntax])
        if(converted_image == :not_found)
          return head :not_found
        elsif(converted_image.nil?)
          return head :not_implemented
        else
          send_file converted_image.path, :status => :ok, :type => 'application/dicom'
        end
      ensure
        converted_image.close if converted_image.respond_to?(:close)
      end
    elsif(@wado_request[:chosen_content_type].start_with?('image/'))
      image_bitmap_data = image_to_bitmap
      if(image_bitmap_data.nil?)
        return head :not_implemented
      else
        send_data image_bitmap_data, :status => :ok, :type => @wado_request[:chosen_content_type]
      end
    else
      return head :bad_request
    end
  end

  protected

  def authorize_user!
    authorize! :read, Image
  end

  def skip_trackable
    request.env['devise.skip_trackable'] = true
  end

  def check_request_type
    if(params[:requestType] != 'WADO')
      head :bad_request
      return false
    end

    return true
  end

  def read_wado_parameters
    @wado_request = {}

    @wado_request[:acceptable_media_types] = request.headers['Accept']

    @wado_request[:object_uid] = params[:objectUID]

    @wado_request[:content_type] = params[:contentType]
    @wado_request[:content_type] = @wado_request[:content_type].split(',') unless @wado_request[:content_type].nil?
    @wado_request[:content_type] ||= 'image/jpeg'
    @wado_request[:charset] = params[:charset]
    @wado_request[:charset] = @wado_request[:charset].split(',') unless @wado_request[:charset].nil?

    @wado_request[:anonymize] = params[:anonymize] == 'yes'
    @wado_request[:annotations] = params[:annotation]
    @wado_request[:annotations] = @wado_request[:annotations].split(',') unless @wado_request[:annotations].nil?

    @wado_request[:rows] = params[:rows]
    @wado_request[:rows] = @wado_request[:rows].to_i unless @wado_request[:rows].nil?
    @wado_request[:columns] = params[:columns]
    @wado_request[:columns] = @wado_request[:columns].to_i unless @wado_request[:columns].nil?
    @wado_request[:region] = params[:region]
    @wado_request[:region] = @wado_request[:region].split(',').map {|s| s.to_f} unless @wado_request[:region].nil?

    @wado_request[:window_center] = params[:windowCenter]
    @wado_request[:window_center] = @wado_request[:window_center].to_f unless @wado_request[:window_center].nil?
    @wado_request[:window_width] = params[:windowWidth]
    @wado_request[:window_width] = @wado_request[:window_width].to_f unless @wado_request[:window_width].nil?

    @wado_request[:frame_number] = params[:frameNumber]
    @wado_request[:frame_number] = @wado_request[:frame_number].to_i unless @wado_request[:frame_number].nil?

    @wado_request[:image_quality] = params[:imageQuality]
    @wado_request[:image_quality] = @wado_request[:image_quality].to_i unless @wado_request[:image_quality].nil?

    @wado_request[:presentation_uid] = params[:presentationUID]
    @wado_request[:presentation_series_uid] = params[:presentationSeriesUID]

    pp @wado_request
  end

  def parse_transfer_syntax
    @wado_request[:transfer_syntax] =
      case params[:transferSyntax]
      when '1.2.840.10008.1.2' then :implicit_vr_little_endian
      when '1.2.840.10008.1.2.1' then :explicit_vr_little_endian
      when '1.2.840.10008.1.2.2' then :explicit_vr_big_endian
      when '1.2.840.10008.1.2.4.57' then :jpeg_lossless
      when '1.2.840.10008.1.2.4.70' then :jpeg_lossless_first_order
      when '1.2.840.10008.1.2.5' then :rle_lossless
      when '1.2.840.10008.1.2.4.90' then :jpeg_2000_lossless
      when '1.2.840.10008.1.2.4.50' then :jpeg_baseline
      when '1.2.840.10008.1.2.4.51' then :jpeg_extended
      when '1.2.840.10008.1.2.4.91' then :jpeg_2000_lossy
      end
  end

  def find_supported_content_type
    @wado_request[:content_type].each do |content_type|
      if(['application/dicom', 'image/jpeg', 'image/png', 'image/tiff'].include?(content_type))
        @wado_request[:chosen_content_type] = content_type
        break
      end
    end

    @wado_request[:chosen_content_type] ||= 'image/jpeg'
  end

  def find_image
    return head :bad_request if @wado_request[:object_uid].nil?
    return head :not_found unless @wado_request[:object_uid].start_with?(Rails.application.config.wado_dicom_prefix)

    image_id = @wado_request[:object_uid].slice(Rails.application.config.wado_dicom_prefix.length..-1).to_i

    @image = Image.where(:id => image_id).first
    authorize! :read, @image
    pp @image
    return head :not_found if @image.nil?

    return true
  end

  def image_to_transfer_syntax(transfer_syntax)
    # If transfer syntax is not specified, the image will be returned
    # as is. If there is a requested transfer syntax in the WADO query
    # we do the conversion. This is for Mac OS X Weasis clients, that
    # do not have JPEG2000 codecs and request a different transfer
    # syntax, if the file cannot be decoded by the viewer.
    return image_file if transfer_syntax.nil?
    return image_file unless [:explicit_vr_little_endian, :explicit_vr_big_endian, :implicit_vr_little_endian].include?(transfer_syntax)

    transfer_syntax_option =
      case transfer_syntax
      when :explicit_vr_little_endian then '+te'
      when :explicit_vr_big_endian then '+tb'
      when :implicit_vr_little_endian then '+ti'
      else ''
      end

    tempfile = Tempfile.new(["#{@image.id}_converted", '.dcm'])
    puts "CONVERT COMMAND: #{Rails.application.config.dcmconv} #{transfer_syntax_option} '#{@image.absolute_image_storage_path}' '#{tempfile.path}'"
    `#{Rails.application.config.dcmconv} #{transfer_syntax_option} '#{@image.absolute_image_storage_path}' '#{tempfile.path}'`
    tempfile
  end

  def image_file
    File.new(@image.absolute_image_storage_path)
  rescue Errno::ENOENT => _e
    Rails.logger.warn "WADO file not found: #{@image.absolute_image_storage_path}"
    :not_found
  end

  def image_to_bitmap
    return nil unless (['image/jpeg', 'image/png', 'image/tiff'].include?(@wado_request[:chosen_content_type]))

    dicom_meta_header, dicom_metadata = @image.dicom_metadata
    return nil if (dicom_metadata['0028,0010'].nil? || dicom_metadata['0028,0011'].nil?)
    original_rows = dicom_metadata['0028,0010'][:value].to_i
    original_columns = dicom_metadata['0028,0011'][:value].to_i

    # check content_type, convert accordingly
    output_format_switch = case @wado_request[:chosen_content_type]
                           when 'image/jpeg' then '+oj'
                           when 'image/png' then '+on'
                           when 'image/tiff' then '+ot'
                           else '+oj'
                           end

    # scale
    scale_option = '+a '
    if(@wado_request[:columns] and @wado_request[:rows])
      if(@wado_request[:rows].to_f/original_rows.to_f < @wado_request[:columns].to_f/original_columns.to_f)
        scale_option += "+Syv #{@wado_request[:rows]}"
      else
        scale_option += "+Sxv #{@wado_request[:columns]}"
      end
    else
      scale_option += "+Sxv #{@wado_request[:columns]}" unless @wado_request[:columns].nil?
      scale_option += "+Syv #{@wado_request[:rows]}" unless @wado_request[:rows].nil?
    end

    # clip
    clip_option = ''
    unless(@wado_request[:region].nil?)
      left = (original_columns*@wado_request[:region][0]).floor
      top = (original_rows*@wado_request[:region][1]).floor
      right = (original_columns*@wado_request[:region][2]).floor
      bottom = (original_rows*@wado_request[:region][3]).floor

      width = right-left
      height = bottom-top


      clip_option = "+C #{left} #{top} #{width} #{height}" if(width > 0 and height > 0)
    end

    # apply window
    window_option = ''
    if(@wado_request[:window_width] and @wado_request[:window_center])
      window_option = "+Ww #{@wado_request[:window_center]} #{@wado_request[:window_width]}"
    end

    # can all be done in one step using dcmj2pnm
    image_data = `#{Rails.application.config.dcmj2pnm} #{scale_option} #{clip_option} #{window_option} #{output_format_switch} '#{@image.absolute_image_storage_path}'`

    return image_data
  end
end

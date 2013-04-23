# -*- coding: utf-8 -*-
class WadoController < ApplicationController
  #before_filter :authenticate_user!
  #before_filter :authorize_user!
  
  before_filter :check_request_type

  before_filter :read_wado_parameters
  before_filter :parse_transfer_syntax
  before_filter :find_image

  # we only support single/multi-frame dicom images as objects

  def wado
    if(@wado_request[:content_type] == 'application/dicom')
      converted_image = image_to_transfer_syntax(@wado_request[:transfer_syntax])
      if(converted_image.nil?)
        return head :not_implemented
      else
        send_file converted_image.path, :status => :ok, :type => 'application/dicom'
        converted_image.unlink
      end
    elsif(@wado_request[:content_type].start_with?('image/'))      
      # check content_type, convert accordingly
      # scale
      # clip
      # apply window
      # can all be done in one step using dcmj2pnm
    else
      return head :bad_request
    end

    head :ok
  end

  protected

  def authorize_user!
    authorize! :read, Image
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

    @wado_request[:transfer_syntax] = params[:transferSyntax]    

    pp @wado_request
  end

  def parse_transfer_syntax
    transfer_syntax_uid = @wado_request[:transfer_syntax]
    transfer_syntax_uid ||= '1.2.840.10008.1.2.1' # default: Explicit VR Little Endian

    @wado_request[:transfer_syntax] = case transfer_syntax_uid
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
                                      else then :implicit_vr_little_endian
                                      end
  end

  def find_image
    return head :bad_request if @wado_request[:object_uid].nil?
    return head :not_found unless @wado_request[:object_uid].start_with?(Rails.application.config.wado_dicom_prefix)

    image_id = @wado_request[:object_uid].slice(Rails.application.config.wado_dicom_prefix.length..-1).to_i

    @image = Image.where(:id => image_id).first
    pp @image
    return head :not_found if @image.nil?

    return true
  end

  def image_to_transfer_syntax(transfer_syntax)
    return nil unless [:explicit_vr_little_endian, :explicit_vr_big_endian, :implicit_vr_little_endian].include?(transfer_syntax)

    transfer_syntax_option = case transfer_syntax
                             when :explicit_vr_little_endian then '+te'
                             when :explicit_vr_big_endian then '+tb'
                             when :implicit_vr_little_endian then '+ti'
                             else ''
                             end

    
    tempfile = Tempfile.new(["#{@image.id}_converted", '.dcm'])
    tempfile.close

    `#{Rails.application.config.dcmconv} #{transfer_syntax_option} '#{@image.absolute_image_storage_path}' '#{tempfile.path}'`

    return tempfile
  end
end

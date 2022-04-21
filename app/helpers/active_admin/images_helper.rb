module ActiveAdmin::ImagesHelper
  def dicom_value_hint(type, text = nil)
    "<span class=\"dicom_value_hint dicom_value_#{type}\">#{text || type}</span>".html_safe
  end


  def pretty_print_dicom_tag(value, vr)
    return dicom_value_hint("null") if value.nil?

    case vr
    when 'LO'
      if value.length == 0
        dicom_value_hint("null", "zero-length")
      else
        value
      end
    when 'OB'
      dicom_value_hint("omitted", "binary data omitted")
    when 'DA'
      begin
        return Date.strptime(value, '%Y%m%d').to_s
      rescue ArgumentError
        return value
      end
    when 'DT'
      datetime = parse_datetime(value, '%Y%m%d%H%M%S.%N%z')
      datetime = parse_datetime(value, '%Y%m%d%H%M%S.%N') if datetime.nil?
      datetime = parse_datetime(value, '%Y%m%d%H%M%S') if datetime.nil?

      if datetime.nil?
        return value
      else
        return datetime
      end
    when 'TM'
      time = parse_datetime(value, '%H%M%S.%N')
      time = parse_datetime(value, '%H%M%S') if time.nil?

      if time.nil?
        return value
      else
        return time.strftime('%H:%M:%S.%N')
      end
    else
      value
    end
  end

  def dicom_metadata_rows(metadata, level: 0)
    render(
      partial: "admin/images/dicom_metadata_rows",
      locals: {
        metadata: metadata,
        level: level
      }
    )
  end

  def dicom_metadata_row_indent(level)
    if level > 0
      "<div class=\"dicom_metadata_row_indent\" style=\"width: #{36*level}px\">&nbsp;</div>".html_safe
    else
      ""
    end
  end

  def dicom_metadata_row_dropdown(image_series, element)
    render(
      partial: "admin/images/dicom_metadata_row_dropdown",
      locals: {
        image_series: image_series,
        element: element
      }
    )
  end

  def parse_datetime(value, format)
    return DateTime.strptime(value, format)
  rescue ArgumentError
    return nil
  end
end

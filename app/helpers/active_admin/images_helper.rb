module ActiveAdmin::ImagesHelper
  def pretty_print_dicom_tag(value, vr)
    case vr
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

  def parse_datetime(value, format)
    return DateTime.strptime(value, format)
  rescue ArgumentError
    return nil
  end
end

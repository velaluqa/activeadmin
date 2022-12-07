class TurnipHelper
  class << self
    def find_record(type, identifier)
      record =
        case type
        when 'BackgroundJob' then BackgroundJob.find_by(id: identifier)
        when 'Study' then Study.find_by(name: identifier)
        when 'Center' then Center.find_by(name: identifier)
        when 'Patient' then Patient.find_by(subject_id: identifier)
        when 'Visit' then Visit.find_by(visit_number: identifier)
        when 'ImageSeries' then ImageSeries.find_by(name: identifier)
        when 'Image' then
          image_series_identifier, image_index = identifier.split("#")
          image_series = ImageSeries.find_by(name: image_series_identifier)
          image_series.images.order(id: :asc)[image_index.to_i - 1]
        when 'User' then User.find_by(username: identifier)
        when 'Role' then Role.find_by(title: identifier)
        when 'EmailTemplate' then EmailTemplate.find_by(name: identifier)
        end
      fail "Cannot find #{type} with identifier #{identifier}" if record.nil?

      record
    end
  end
end

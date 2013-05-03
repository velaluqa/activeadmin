xml.instruct!
xml.wado_query('xmlns' => 'http://www.weasis.org/xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'wadoURL' => wado_url, 'requireOnlySOPInstanceUID' => 'true', 'additionnalParameters' => "&authentication_token=#{@authentication_token}") do
  @patients.each do |patient|
    xml.Patient('PatientName' => patient[:name]) do
      patient[:visits].each do |visit|
        xml.Study('StudyDescription' => visit[:name]) do
          visit[:image_series].each do |image_series|
            xml.Series('SeriesDescription' => image_series[:name]) do
              image_series[:images].each_with_index do |image, i|
                xml.Instance('SOPInstanceUID' => image.wado_uid, 'InstanceNumber' => i+1)
              end
            end
          end
        end
      end
    end
  end
end

xml.instruct!
xml.wado_query('xmlns' => 'http://www.weasis.org/xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'wadoURL' => wado_url, 'requireOnlySOPInstanceUID' => 'true', 'additionnalParameters' => "&authentication_token=#{@authentication_token}", 'overrideDicomTagsList' => '0x00100010,0x00081030,0x0008103E,0x00200011') do
  @patients.each do |patient|
    xml.Patient('PatientName' => patient[:name], 'PatientID' => patient[:id].to_s) do
      patient[:visits].each do |visit|
        xml.Study('StudyDescription' => visit[:name], 'StudyInstanceUID' => Rails.application.config.wado_dicom_prefix + visit[:id].to_s) do
          visit[:image_series].each do |image_series|
            xml.Series('SeriesDescription' => image_series[:id].to_s + ' - ' + image_series[:name], 'SeriesNumber' => image_series[:id].to_s, 'SeriesInstanceUID' => Rails.application.config.wado_dicom_prefix + image_series[:id].to_s) do
              image_series[:images].each_with_index do |image, i|
                xml.Instance('SOPInstanceUID' => image.wado_uid, 'InstanceNumber' => i + 1)
              end
            end
          end
        end
      end
    end
  end
end

xml.instruct!
xml.wado_query('xmlns' => 'http://www.weasis.org/xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'wadoURL' => wado_url, 'requireOnlySOPInstanceUID' => 'true', 'additionnalParameters' => "&authentication_token=#{@authentication_token}") do
  xml.Patient do
    xml.Study do
      xml.Series do
        @images.each_with_index do |image, i|
          xml.Instance('SOPInstanceUID' => image.wado_uid, 'InstanceNumber' => i+1)
        end
      end
    end
  end
end

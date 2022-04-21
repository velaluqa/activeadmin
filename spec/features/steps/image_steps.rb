step 'a/an (DICOM )image for image series :image_series_instance' do |image_series|
  @image = create(:image, image_series: image_series)
end

step 'a DICOM image for :image_series_instance with metadata:' do |image_series, metadata|
  tmp_file = Tempfile.new
  tmp_dicom = DICOM::DObject.read("spec/files/test.dicom")

  metadata.each do |tag, value|
    tmp_dicom[tag].value = value
  end

  tmp_dicom.write(tmp_file.path)

  @image = create(
    :image,
    image_series: image_series,
    dicom_path: tmp_file.path
  )
end

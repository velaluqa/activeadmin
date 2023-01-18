step 'a/an (DICOM )image for image series :image_series_instance' do |image_series|
  @image = create(:image, image_series: image_series)
end

step 'a DICOM image for :image_series_instance with metadata:' do |image_series, metadata|
  @image = create(
    :image,
    image_series: image_series,
    override_metadata: metadata.to_h
  )
end

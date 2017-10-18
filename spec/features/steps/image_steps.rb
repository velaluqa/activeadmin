step 'a/an image for image series :image_series_instance' do |image_series|
  @image = create(:image, image_series: image_series)
end

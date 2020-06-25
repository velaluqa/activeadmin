step 'a/a required series :string for visit :visit_instance with:' do |name, visit, table|
  @required_series = RequiredSeries.where(name: name, visit: visit).first_or_create
  options = {}
  table.to_a.each do |attribute, value|
    options[attribute.to_sym] = value
    options[:image_series_id] = ImageSeries.find_by(name: value).id if attribute == 'image_series'
  end
  @required_series.update_attributes(options)
end

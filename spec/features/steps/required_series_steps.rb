step 'a/a required series :string for visit :visit_instance with:' do |name, visit, table|
  @required_series = RequiredSeries.where(name: name, visit: visit).first_or_create
  options = {}
  table.to_a.each do |attribute, value|
    if attribute == 'image_series'    
      options[:image_series_id] = ImageSeries.find_by(name: value).id 
    else
      options[attribute.to_sym] = value
    end
  end
  @required_series.update(options)
end
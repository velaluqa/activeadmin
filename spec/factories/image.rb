FactoryBot.define do
  factory :image do
    image_series

    after(:create) do |image|
      path = ERICA.image_storage_path.join(image.image_storage_path)
      FileUtils.mkdir_p(path.dirname.to_s)
      FileUtils.cp("spec/files/test.dicom", path.to_s)
    end
  end
end

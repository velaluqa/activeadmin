FactoryBot.define do
  factory :image do
    image_series

    mimetype { 'application/dicom' }
    sha256sum do
      File.open("spec/files/test.dicom", 'rb') do |f|
        Digest::SHA256.hexdigest(f.read)
      end
    end

    after(:create) do |image|
      path = ERICA.image_storage_path.join(image.image_storage_path)
      FileUtils.mkdir_p(path.dirname.to_s)
      FileUtils.cp("spec/files/test.dicom", path.to_s)
    end
  end
end

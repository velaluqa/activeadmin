FactoryBot.define do
  factory :image do
    transient do
      dicom_path { nil }
      tmp_file { Tempfile.new }
      override_metadata { nil }
    end

    image_series

    mimetype { 'application/dicom' }
    sha256sum do
      File.open(dicom_path || "spec/files/test.dicom", 'rb') do |f|
        Digest::SHA256.hexdigest(f.read)
      end
    end

    after(:build) do |image, e|
      dicom_path = e.dicom_path || "spec/files/test.dicom"

      if e.override_metadata
        dicom = DICOM::DObject.read(dicom_path)

        e.override_metadata.each_pair do |tag, value|
          if dicom.exists?(tag)
            dicom[tag].value = value
          else
            dicom.add_element(tag, value)
          end
        end

        dicom.write(e.tmp_file.path)
      else
        FileUtils.cp(dicom_path, e.tmp_file.path)
      end
      image.sha256sum = Digest::SHA256.hexdigest(File.read(e.tmp_file.path))
    end

    after(:create) do |image, e|
      image_path = ERICA.image_storage_path.join(image.image_storage_path)

      FileUtils.mkdir_p(image_path.dirname.to_s)
      FileUtils.cp(e.tmp_file.path, image_path.to_s)
    end
  end
end

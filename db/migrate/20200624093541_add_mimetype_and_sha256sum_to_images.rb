class AddMimetypeAndSha256sumToImages < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column(:images, :mimetype, :string, null: true)
    add_column(:images, :sha256sum, :string, null: true)

    reversible do |dir|
      dir.up do
        Image.where("sha256sum is null").find_each do |image|
          puts "Calculating checksum for #{image.image_storage_path} ..."
          next unless File.exists?(image.absolute_image_storage_path)
          checksum =
            File.open(image.absolute_image_storage_path, 'rb') do |f|
            Digest::SHA256.hexdigest(f.read)
          end
          image.sha256sum = checksum
          image.mimetype = "application/dicom"
          image.save!
        end
      end
    end
  end
end

DICOM_TAG = "0010,0030" # represents the PatientComments tag

describe CleanDicomTagWorker do
  describe '#perform' do

    let!(:override_metadata) { { DICOM_TAG => "Deletable Value" } }

    let(:background_job) { create(:background_job, name: "Test Job") }

    let(:study) { create(:study) }
    let(:center) { create(:center, study: study) }
    let(:patient) { create(:patient, center: center) }

    let(:image_series1) { create(:image_series, patient: patient) }
    let(:image11) { create(:image, image_series: image_series1, override_metadata: override_metadata )}
    let(:image12) { create(:image, image_series: image_series1, override_metadata: override_metadata )}

    let(:image_series2) { create(:image_series, patient: patient) }
    let(:image21) { create(:image, image_series: image_series2, override_metadata: override_metadata )}
    let(:image22) { create(:image, image_series: image_series2, override_metadata: override_metadata )}

    describe 'for image series' do
      let(:run_worker) do
        CleanDicomTagWorker.new.perform(
          background_job.id.to_s,
          "ImageSeries",
          image_series1.id,
          DICOM_TAG
        )
      end

      it 'updates the background job status accordingly' do
        expect(background_job.progress).to eq(0.0)

        run_worker

        background_job.reload
        expect(background_job.failed?).to be_falsy
        expect(background_job.progress).to eq(1.0)
      end

      it 'backups all changed image files' do
        images = [image11, image12]
        previous_checksums = images.map(&:sha256sum)

        run_worker

        date = Date.today.strftime('%Y-%m-%d')

        images.each_with_index do |image, i|
          backup_file_path = ERICA.backup_path.join("images", date, "#{image.id}.0")
          expect(File).to exist(backup_file_path)

          backup_file_checksum = Digest::SHA256.hexdigest(File.read(backup_file_path))
          expect(backup_file_checksum).to eq(previous_checksums[i])
        end
      end

      it 'changes all images of the image series' do
        images = [image11, image12]

        images.each do |image|
          tag_value = image.dicom_metadata[1][DICOM_TAG][:value]
          expect(tag_value).to eq("Deletable Value")

          file_checksum = Digest::SHA256.hexdigest(File.read(ERICA.image_storage_path.join(image.image_storage_path).to_s))
          expect(image.sha256sum).to eq(file_checksum)
        end

        run_worker

        images.each do |image|
          image.reload

          tag_value = image.dicom_metadata[1][DICOM_TAG][:value]
          expect(tag_value).to eq("redacted")

          file_checksum = Digest::SHA256.hexdigest(File.read(ERICA.image_storage_path.join(image.image_storage_path).to_s))
          expect(image.sha256sum).to eq(file_checksum)
        end
      end

      it 'does not change images of other image series' do
        images = [image21, image22]

        images.each do |image|
          expect(image.dicom_metadata[1][DICOM_TAG][:value]).to eq("Deletable Value")
        end

        run_worker

        images.each do |image|
          expect(image.dicom_metadata[1][DICOM_TAG][:value]).to eq("Deletable Value")
        end
      end
    end
  end
end

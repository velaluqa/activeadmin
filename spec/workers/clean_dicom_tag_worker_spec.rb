DICOM_TAG = "0010,0030" # represents the PatienBirthDate tag

describe CleanDicomTagWorker do
  describe '#perform' do

    let!(:override_metadata) { { DICOM_TAG => "Deletable Value" } }

    let!(:background_job) { create(:background_job, name: "Test Job") }

    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }

    let!(:image_series1) { create(:image_series, patient: patient) }
    let!(:image11) { create(:image, image_series: image_series1, override_metadata: override_metadata )}
    let!(:image12) { create(:image, image_series: image_series1, override_metadata: override_metadata )}

    let!(:image_series2) { create(:image_series, patient: patient) }
    let!(:image21) { create(:image, image_series: image_series2, override_metadata: override_metadata )}
    let!(:image22) { create(:image, image_series: image_series2, override_metadata: override_metadata )}

    shared_examples "removes tag for image" do |label|
      it "backups file of #{label}" do
        previous_checksum = image.sha256sum

        run_worker

        date = Date.today.strftime('%Y-%m-%d')

        backup_file_path = ERICA.backup_path.join("images", date, "#{image.id}.0")
        expect(File).to exist(backup_file_path)

        backup_file_checksum = Digest::SHA256.hexdigest(File.read(backup_file_path))
        expect(backup_file_checksum).to eq(previous_checksum)
      end

      it "removes dicom tag from file for #{label}" do
        tag_value = image.dicom_metadata[1][DICOM_TAG][:value]
        expect(tag_value).to eq("Deletable Value")

        file_checksum = Digest::SHA256.hexdigest(File.read(ERICA.image_storage_path.join(image.image_storage_path).to_s))
        expect(image.sha256sum).to eq(file_checksum)

        run_worker

        image.reload

        tag = image.dicom_metadata[1][DICOM_TAG]
        expect(tag[:value]).to be_nil

        file_checksum = Digest::SHA256.hexdigest(File.read(ERICA.image_storage_path.join(image.image_storage_path).to_s))
        expect(image.sha256sum).to eq(file_checksum)
      end

      it "logs original attributes to `0400,0561` for #{label}" do
        run_worker

        image.reload

        tag = image.dicom_metadata[1]["0400,0561"]

        expect(tag).not_to be_nil
        expect(tag.dig(:items, 0, "0400,0550", :items, 0, "0010,0030")).to include(name: "PatientBirthDate", value: nil)
        expect(tag.dig(:items, 0, "0400,0563")).to include(value: "Pharmtrace ERICA SaaS #{ERICA.version}")
        expect(tag.dig(:items, 0, "0400,0565")).to include(value: "COERCE")
      end
    end

    shared_examples "keeps tag value for image" do |label|
      it "does not change image #{label}" do
        expect(image.dicom_metadata[1][DICOM_TAG][:value]).to eq("Deletable Value")

        run_worker

        expect(image.dicom_metadata[1][DICOM_TAG][:value]).to eq("Deletable Value")
      end
    end

    describe 'failing retries' do
      let(:background_job) { create(:background_job, name: 'Test job') }

      it "sets background job status to `failed`" do
        CleanDicomTagWorker.within_sidekiq_retries_exhausted_block({ "args" => [background_job.id] }) do
          expect(CleanDicomTagWorker)
            .to receive(:fail_job_after_exhausting_retries).and_call_original
        end

        background_job.reload

        expect(background_job).to be_failed
      end
    end

    describe 'for image series' do
      let(:run_worker) do
        CleanDicomTagWorker.new.perform(
          background_job.id.to_s,
          {},
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

      it_behaves_like "removes tag for image", "image11" do
        let(:image) { image11 }
      end
      it_behaves_like "removes tag for image", "image12" do
        let(:image) { image12 }
      end

      it_behaves_like "keeps tag value for image", "image21" do
        let(:image) { image21 }
      end
      it_behaves_like "keeps tag value for image", "image22" do
        let(:image) { image22 }
      end
    end
  end
end

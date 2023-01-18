describe SplitMultiFrameDicomWorker do
  describe "#perform" do
    let!(:image_series) { create(:image_series) }
    let(:compressed_path) { "spec/files/multiframe_same_series_uid/compressed_multiframe_1.dcm" }
    let(:decompressed_file) do
      tmp_file = Tempfile.new
      DICOM::FileUtils.ensure_little_endian(compressed_path, tmp_file.path)
      tmp_file
    end

    let(:image) { create(:image, image_series: image_series, dicom_path: decompressed_file.path) }
    let!(:background_job) { create(:background_job) }

    it "replaces uploaded multi-frame `Image` with n single-frame `Image` instances" do
      SplitMultiFrameDicomWorker.new.perform(background_job.id, {}, image.id)

      expect { image.reload }
        .to raise_error(ActiveRecord::RecordNotFound)
      expect(image_series.images.count).to eq(10)
    end
  end
end

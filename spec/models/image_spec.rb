RSpec.describe Image do
  describe 'scope ::searchable' do
    it 'selects search fields' do
      image = create(:image)
      expect(Image.searchable.as_json)
        .to eq [{
          'id' => nil,
          'study_id' => image.image_series.patient.center.study.id,
          'study_name' => image.image_series.patient.center.study.name,
          'text' => "#{image.image_series.series_number}##{image.id}",
          'result_id' => image.id.to_s,
          'result_type' => 'Image'
        }]
    end
  end

  describe '#dicom_metadata' do
    let!(:image) { create(:image) }
    let(:metadata) { image.dicom_metadata }

    it 'sequences as nested hashes' do
      expect(metadata[1]).to include("0040,0275" => include(name: "RequestAttributesSequence", tag: "0040,0275", vr: "SQ"))

      items = metadata[1]["0040,0275"][:items]
      expect(items).to be_an(Array)
      expect(items).to include(include("0040,0007" => include(name: "ScheduledProcedureStepDescription")))
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @patient = create(:patient, id: 1, center: @center)
      @image_series = create(:image_series, id: 1, patient: @patient)
      @image_series2 = create(:image_series, id: 2, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image = create(:image, id: 1, image_series: @image_series)
      image.write_anonymized_file(File.new('spec/files/test.dicom'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image = create(:image, id: 1, image_series: @image_series)
      image.write_anonymized_file(File.new('spec/files/test.dicom'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image.image_series_id = 2
      image.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/2/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image = create(:image, id: 1, image_series: @image_series)
      image.write_anonymized_file(File.new('spec/files/test.dicom'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1            = create(:study)
      @center11          = create(:center, study: @study1)
      @patient111        = create(:patient, center: @center11)
      @visit1111         = create(:visit, patient: @patient111)
      @image_series11111 = create(:image_series, visit: @visit1111)
      @image111111       = create(:image, image_series: @image_series11111)
      @image111112       = create(:image, image_series: @image_series11111)
      @center12          = create(:center, study: @study1)
      @patient121        = create(:patient, center: @center12)
      @visit1211         = create(:visit, patient: @patient121)
      @image_series12111 = create(:image_series, visit: @visit1211)
      @image121111       = create(:image, image_series: @image_series12111)
      @image121112       = create(:image, image_series: @image_series12111)

      @study2            = create(:study)
      @center21          = create(:center, study: @study2)
      @patient211        = create(:patient, center: @center21)
      @visit2111         = create(:visit, patient: @patient211)
      @image_series21111 = create(:image_series, visit: @visit2111)
      @image211111       = create(:image, image_series: @image_series21111)
      @image211112       = create(:image, image_series: @image_series21111)
      @center22          = create(:center, study: @study2)
      @patient221        = create(:patient, center: @center22)
      @visit2211         = create(:visit, patient: @patient221)
      @image_series22111 = create(:image_series, visit: @visit2211)
      @image221111       = create(:image, image_series: @image_series22111)
      @image221112       = create(:image, image_series: @image_series22111)

      @study3            = create(:study)
      @center31          = create(:center, study: @study3)
      @patient311        = create(:patient, center: @center31)
      @visit3111         = create(:visit, patient: @patient311)
      @image_series31111 = create(:image_series, visit: @visit3111)
      @image311111       = create(:image, image_series: @image_series31111)
      @image311112       = create(:image, image_series: @image_series31111)
      @center32          = create(:center, study: @study3)
      @patient321        = create(:patient, center: @center32)
      @visit3211         = create(:visit, patient: @patient321)
      @image_series32111 = create(:image_series, visit: @visit3211)
      @image321111       = create(:image, image_series: @image_series32111)
      @image321112       = create(:image, image_series: @image_series32111)
    end

    it 'returns the matched images by a single study' do
      expect(Image.by_study_ids(@study1.id))
        .to match_array [
          @image111111, @image111112, @image121111, @image121112
        ]
    end

    it 'returns the matched images by multiple studies' do
      expect(Image.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @image111111, @image111112, @image121111, @image121112,
          @image311111, @image311112, @image321111, @image321112
        ]
      expect(Image.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @image111111, @image111112, @image121111, @image121112,
          @image311111, @image311112, @image321111, @image321112
        ]
    end
  end

  describe '#write_anonymized_file' do
    it 'anonymizes a file and writes it to the image_storage' do
      @image = create(:image)
      @image.write_anonymized_file(File.new('spec/files/test.dicom'))
      dicom = DICOM::DObject.read('spec/files/test.dicom')
      expect(dicom.patients_name.value).to eq 'WRIX'
      dicom = DICOM::DObject.read(@image.absolute_image_storage_path)
      expect(dicom.patients_name.value).to eq "#{@image.image_series.patient.name}"
    end

    it 'handles explicit big endian files by conversion to explicit little endian' do
      @image = create(:image)
      @image.write_anonymized_file(File.new('spec/files/test_bigendian.dicom'))
      dicom = DICOM::DObject.read(@image.absolute_image_storage_path)
      expect(@image.dicom_metadata).to be_a(Array)
      expect(@image.dicom_metadata[1]["0002,0010"][:value]).to eq("1.2.840.10008.1.2.1")
      expect(dicom.patients_name.value).to eq "#{@image.image_series.patient.name}"
    end

    it "caches dicomweb metadata for patient" do
      expectedKeys = ["00080005", "00080020", "00080030", "00080050", "00080090", "00100010", "00100020", "0020000D", "00200010"]

      @image = create(:image)
      @image.write_anonymized_file(File.new('spec/files/test.dicom'))

      Sidekiq::Worker.drain_all
      @image.reload

      expect(@image.image_series.patient.cache["dicomwebMetadata"].keys).to match_array(expectedKeys)
    end

    it "caches dicomweb metadata for image series" do
      expectedKeys =  ["00080005", "00080060", "0008103E", "0020000D", "0020000E", "00200011"]

      @image = create(:image)
      @image.write_anonymized_file(File.new('spec/files/test.dicom'))

      Sidekiq::Worker.drain_all
      @image.reload

      expect(@image.image_series.cache["dicomwebMetadata"].keys).to match_array(expectedKeys)
    end

    it "caches dicomweb metadata for image" do
      expectedKeys = ["00080016", "00080018", "00080060", "0020000D", "0020000E", "00200032", "00200037", "00280002", "00280004", "00280010", "00280011", "00280030", "00280100", "00280101", "00280102", "00280103", "00281050", "00281051"]

      @image = create(:image)
      @image.write_anonymized_file(File.new('spec/files/test.dicom'))

      Sidekiq::Worker.drain_all
      @image.reload

      expect(@image.cache["dicomwebMetadata"].keys).to match_array(expectedKeys)
    end
  end

  describe 'versioning' do
    describe 'create' do
      before(:each) do
        @image = create(:image)
        @study_id = @image.study.id
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Image').last
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'update' do
      before(:each) do
        @image = create(:image)
        @study_id = @image.study.id
        @image.updated_at = DateTime.now
        @image.save!
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Image').last
        expect(version.event).to eq 'update'
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'destroy' do
      before(:each) do
        @image = create(:image)
        @study_id = @image.study.id
        @image.destroy
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Image').last
        expect(version.event).to eq 'destroy'
        expect(version.study_id).to eq @study_id
      end
    end
  end
end

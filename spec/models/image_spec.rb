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
          'result_id' => image.id,
          'result_type' => 'Image'
        }]
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
      image.write_anonymized_file(File.read('spec/files/test.dicom'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image = create(:image, id: 1, image_series: @image_series)
      image.write_anonymized_file(File.read('spec/files/test.dicom'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image.image_series_id = 2
      image.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/2/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/__unassigned/1/1'))
      image = create(:image, id: 1, image_series: @image_series)
      image.write_anonymized_file(File.read('spec/files/test.dicom'))
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
      @image.write_anonymized_file(File.read('spec/files/test.dicom'))
      dicom = DICOM::DObject.read('spec/files/test.dicom')
      expect(dicom.patients_name.value).to eq 'WRIX'
      dicom = DICOM::DObject.read(@image.absolute_image_storage_path)
      expect(dicom.patients_name.value).to eq "#{@image.image_series.patient.center_id}#{@image.image_series.patient.subject_id}"
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

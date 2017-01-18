RSpec.describe Version do
  it { should have_many(:notifications) }

  describe '::ordered_find_each' do
    before(:each) do
      expect(Version.count).to eq(0)
      250.times { create(:study) }
    end

    it 'finds all ordered' do
      versions = Version
                   .select(:id)
                   .where('"versions"."id" <= ?', 245)
                   .order('"versions"."id" DESC')
      ids = []
      versions.ordered_find_each do |version|
        ids.push(version.id)
        # ensure event when a new version is added, that the batches
        # are found correctly
        create(:user) if version.id == 50
      end
      expect(ids.length).to eq(245)
      expect(ids).to eq((1..245).to_a.reverse)
    end
  end

  describe 'scope ::of_study_resource' do
    before(:each) do
      @study = create(:study)
      @study_version = Version.last
      @center = create(:center, study: @study)
      @center_version = Version.last
      @patient = create(:patient, center: @center)
      @patient_version = Version.last
      @visit = create(:visit, patient: @patient)
      @visit_version = Version.last
      @image_series = create(:image_series, patient: @patient)
      @image_series_version = Version.last
    end

    describe 'with resource `Patient`' do
      it 'includes patient version' do
        expect(Version.of_study_resource(@study, 'Patient')).to include(@patient_version)
        expect(Version.of_study_resource(@study, 'Patient')).not_to include(@visit_version)
        expect(Version.of_study_resource(@study, 'Patient')).not_to include(@image_series_version)
      end
    end

    describe 'with resource `Visit`' do
      it 'includes visit version' do
        expect(Version.of_study_resource(@study, 'Visit')).not_to include(@patient_version)
        expect(Version.of_study_resource(@study, 'Visit')).to include(@visit_version)
        expect(Version.of_study_resource(@study, 'Visit')).not_to include(@image_series_version)
      end
    end

    describe 'with resource `ImageSeries`' do
      it 'includes image_series version' do
        expect(Version.of_study_resource(@study, 'ImageSeries')).not_to include(@patient_version)
        expect(Version.of_study_resource(@study, 'ImageSeries')).not_to include(@visit_version)
        expect(Version.of_study_resource(@study, 'ImageSeries')).to include(@image_series_version)
      end
    end

    describe 'with resource `RequiredSeries`' do
      it 'includes required_series version' do
        expect(Version.of_study_resource(@study, 'RequiredSeries')).not_to include(@patient_version)
        expect(Version.of_study_resource(@study, 'RequiredSeries')).to include(@visit_version)
        expect(Version.of_study_resource(@study, 'RequiredSeries')).not_to include(@image_series_version)
      end
    end
  end
end

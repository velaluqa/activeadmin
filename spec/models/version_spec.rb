RSpec.describe Version do
  it { should have_many(:notifications) }

  describe '::ordered_find_each' do
    before(:each) do
      expect(Version.count).to eq(0)
      250.times { create(:study) }
      expect(Version.count).to eq(250)
      @last_id = Version.last.id
      @first_id = Version.first.id
    end

    it 'finds all ordered' do
      versions = Version
                   .select(:id)
                   .where('"versions"."id" >= ?', @first_id)
                   .where('"versions"."id" <= ?', @last_id - 5)
                   .order('"versions"."id" DESC')
      ids = []
      versions.ordered_find_each do |version|
        ids.push(version.id)
        # Ensure that the batches are ordered correctly even when a
        # new version is added.
        create(:user) if version.id == 50
      end
      # expect(ids.length).to eq(245)
      expect(ids).to eq((@first_id..(@last_id - 5)).to_a.reverse)
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

  describe 'callback' do
    with_model :ObservableModel do
      table do |t|
        t.string :title
        t.timestamps null: false
      end
      model do
        has_paper_trail class_name: 'Version'
      end
    end

    describe 'on create' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(model.versions.last.id)
      end
    end
    describe 'on update' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        model.title = 'bar'
        model.save!
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(model.versions.last.id)
      end
    end
    describe 'on destroy' do
      it 'triggers notification profiles' do
        model = ObservableModel.create(title: 'foo')
        model.destroy
        expect(TriggerNotificationProfiles).to have_enqueued_sidekiq_job(Version.last.id)
      end
    end
  end
end

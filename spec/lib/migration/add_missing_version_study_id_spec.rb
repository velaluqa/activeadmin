require_dependency 'migration/add_missing_version_study_id'

describe Migration::AddMissingVersionStudyId, silent_output: true do
  before(:each) do
    Version.skip_callback(:save, :before, :add_item_name_as_string)

    @email_template = create(:email_template)
    @notification_profile = create(:notification_profile, email_template: @email_template)
    @user = create(:user)
    @study = create(:study)
    @center = create(:center, code: "100", study: @study)
    @patient = create(:patient, subject_id: "100", center: @center)
    @visit = create(:visit, visit_number: 1, patient: @patient)
    @image_series = create(:image_series, name: "test_series", patient: @patient)
    @image = create(:image, image_series: @image_series)
    @notification = create(
      :notification,
      resource: @image,
      version: @image.versions.last,
      user: @user,
      notification_profile: @notification_profile
    )
  end

  after(:each) do
    Version.set_callback(:save, :before, :add_item_name_as_string)
  end

  let(:run_migration) do
    Version.set_callback(:save, :before, :add_item_name_as_string)
    Migration::AddMissingVersionStudyId.run
    Version.skip_callback(:save, :before, :add_item_name_as_string)
  end

  describe 'for existing hierarchy' do
    before(:each) do
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing study' do
    before(:each) do
      @study.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing center' do
    before(:each) do
      @center.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing patient' do
    before(:each) do
      @patient.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing image_series' do
    before(:each) do
      @image_series.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing image' do
    before(:each) do
      @image.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing visit' do
    before(:each) do
      @visit.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end

  describe 'for missing visit' do
    before(:each) do
      @study.delete
      @center.delete
      @patient.delete
      @image_series.delete
      @image.delete
      @visit.delete
      @notification.delete
      Version.all.each do |version|
        version.study_id = nil
        version.save!
      end
    end

    describe '::run' do
      it 'recreates all study ids' do
        run_migration

        expect(Version.order(:created_at).pluck(:study_id)).to eq([nil, nil, nil] + [@study.id] * 7)
      end
    end
  end
end

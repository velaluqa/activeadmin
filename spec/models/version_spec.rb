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
    let!(:study) { create(:study) }
    let!(:study_version) { Version.last }
    let!(:center) { create(:center, study: study) }
    let!(:center_version) { Version.last }
    let!(:patient) { create(:patient, center: center) }
    let!(:patient_version) { Version.last }
    let!(:visit) { create(:visit, patient: patient) }
    let!(:visit_version) { Version.last }
    let!(:required_series) { create(:required_series, visit: visit, name: 'SPECT_1')}
    let!(:required_series_version) { Version.last }
    let!(:image_series) { create(:image_series, visit: visit, patient: patient) }
    let!(:image_series_version) { Version.last }

    describe 'with resource `Patient`' do
      let(:result) { Version.of_study_resource(study, 'Patient') }

      it 'includes patient version' do
        expect(result).to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `Visit`' do
      let(:result) { Version.of_study_resource(study, 'Visit') }

      it 'includes visit version' do
        expect(result).not_to include(patient_version)
        expect(result).to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `ImageSeries`' do
      let(:result) { Version.of_study_resource(study, 'ImageSeries') }

      it 'includes image_series version' do
        expect(result).not_to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).to include(image_series_version)
        expect(result).not_to include(required_series_version)
      end
    end

    describe 'with resource `RequiredSeries`' do
      let(:result) { Version.of_study_resource(study, 'RequiredSeries') }

      it 'includes required_series version' do
        expect(result).not_to include(patient_version)
        expect(result).not_to include(visit_version)
        expect(result).not_to include(image_series_version)
        expect(result).to include(required_series_version)
      end
    end
  end

  describe '#complete_changes' do
    describe 'for create' do
      let!(:version) do
        Version.create(
          event: 'create',
          item_type: 'Study',
          item_id: 8,
          object: nil,
          object_changes: {
            'id'         => [nil, 8],
            'name'       => [nil, 'Study 1'],
            'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
            'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => [nil, 8],
          'name'       => [nil, 'Study 1'],
          'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
          'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
    describe 'for update' do
      let!(:version) do
        Version.create(
          event: 'update',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: {
            'name'       => ['Study 1', 'Foo Study'],
            'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'name'       => ['Study 1', 'Foo Study'],
          'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
    describe 'for destroy' do
      let!(:version) do
        Version.create(
          event: 'destroy',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: nil
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => [8, nil],
          'name'       => ['Study 1', nil],
          'state'      => [0, nil],
          'created_at' => ['2017-02-24T09:37:31.984Z', nil],
          'updated_at' => ['2017-02-24T09:37:31.984Z', nil]
        }
        expect(version.complete_changes).to eq(expected_changes)
      end
    end
  end

  describe '#complete_attributes' do
    describe 'for create' do
      let!(:version) do
        Version.create(
          event: 'create',
          item_type: 'Study',
          item_id: 8,
          object: nil,
          object_changes: {
            'id'         => [nil, 8],
            'name'       => [nil, 'Study 1'],
            'created_at' => [nil, '2017-02-24T09:37:31.984Z'],
            'updated_at' => [nil, '2017-02-24T09:37:31.984Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'         => 8,
          'name'       => 'Study 1',
          'created_at' => '2017-02-24T09:37:31.984Z',
          'updated_at' => '2017-02-24T09:37:31.984Z'
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
    describe 'for update' do
      let!(:version) do
        Version.create(
          event: 'update',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: {
            'name'       => ['Study 1', 'Foo Study'],
            'updated_at' => ['2017-02-24T09:37:31.984Z', '2017-02-24T09:41:31.675Z']
          }
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'                   => 8,
          'name'                 => 'Foo Study',
          'state'                => 0,
          'created_at'           => '2017-02-24T09:37:31.984Z',
          'updated_at'           => '2017-02-24T09:41:31.675Z',
          'domino_db_url'        => nil,
          'locked_version'       => nil,
          'domino_server_name'   => nil,
          'notes_links_base_uri' => nil
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
    describe 'for destroy' do
      let!(:version) do
        Version.create(
          event: 'destroy',
          item_type: 'Study',
          item_id: 8,
          object: {
            'id'                   => 8,
            'name'                 => 'Study 1',
            'state'                => 0,
            'created_at'           => '2017-02-24T09:37:31.984Z',
            'updated_at'           => '2017-02-24T09:37:31.984Z',
            'domino_db_url'        => nil,
            'locked_version'       => nil,
            'domino_server_name'   => nil,
            'notes_links_base_uri' => nil
          },
          object_changes: nil
        )
      end

      it 'returns complete changes' do
        expected_changes = {
          'id'                   => 8,
          'name'                 => 'Study 1',
          'state'                => 0,
          'created_at'           => '2017-02-24T09:37:31.984Z',
          'updated_at'           => '2017-02-24T09:37:31.984Z',
          'domino_db_url'        => nil,
          'locked_version'       => nil,
          'domino_server_name'   => nil,
          'notes_links_base_uri' => nil
        }
        expect(version.complete_attributes).to eq(expected_changes)
      end
    end
  end

  describe 'callback', transactional_spec: true do
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

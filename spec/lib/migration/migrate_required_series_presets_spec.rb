require 'migration/migrate_required_series_presets'

describe Migration::MigrateRequiredSeriesPresets do
  describe '::run', paper_trail: false do
    let!(:study) do
      Timecop.travel(Time.local(2017, 6, 3, 12, 0, 0))
      Timecop.scale(3600)
      create(:study, configuration: <<CONF.strip_heredoc)
        visit_types:
          baseline:
            required_series:
              SPECT_1:
                tqc: []
              SPECT_2:
                tqc: []
          followup:
            required_series:
              SPECT_1:
                tqc: []
              SPECT_3:
                tqc: []
        image_series_properties: []
CONF
    end
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }

    before(:each) do
      Timecop.return
    end

    describe 'for `create` visit version with visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }

      let!(:version) do
        Timecop.travel(Time.local(2017, 6, 4, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: visit.id,
          event: 'create',
          object: nil,
          object_changes: {
            'patient_id' => [nil, patient.id],
            'visit_number' => [nil, '0001'],
            'visit_type' => [nil, 'baseline']
          },
          study_id: study.id
        )
      end

      before(:each) do
        # We need to reload so that the dates are of the correct
        # precision. When the object is created by ActiveRecord, the
        # date has a precision to the 8th decimal place, but postgres
        # only saves 5 decimal places.
        version.reload
        # Required series are created automatically. To have a clean
        # state we have to remove them first.
        visit.required_series.destroy_all
        Migration::MigrateRequiredSeriesPresets.run
      end

      it 'creates required series presets' do
        expect(RequiredSeries.where(visit: visit).count).to eq(2)
      end
      it 'creates required series presets versions' do
        expect(Version.where(item_type: 'RequiredSeries').count).to eq(2)
        expect(Version.where(item_type: 'RequiredSeries').first.attributes)
          .to include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_1'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version.created_at.as_json],
                  'updated_at' => [nil, version.created_at.as_json]
                ),
                'created_at' => version.created_at,
                'study_id' => study.id
              )
        expect(Version.where(item_type: 'RequiredSeries').last.attributes)
          .to include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_2'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version.created_at.as_json],
                  'updated_at' => [nil, version.created_at.as_json]
                ),
                'created_at' => version.created_at,
                'study_id' => study.id
              )
      end
    end

    describe 'for `update` visit version adding visit type' do
      let!(:visit) { create(:visit, patient: patient) }

      let!(:version) do
        Timecop.travel(Time.local(2017, 6, 4, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: visit.id,
          event: 'update',
          object: JSON.parse(visit.to_json),
          object_changes: {
            'visit_type' => [nil, 'baseline']
          },
          study_id: study.id
        )
      end

      before(:each) do
        # We need to reload so that the dates are of the correct
        # precision. When the object is created by ActiveRecord, the
        # date has a precision to the 8th decimal place, but postgres
        # only saves 5 decimal places.
        version.reload
        Migration::MigrateRequiredSeriesPresets.run
      end

      it 'creates required series presets' do
        expect(RequiredSeries.where(visit: visit).count).to eq(2)
      end
      it 'creates required series preset versions' do
        expect(Version.where(item_type: 'RequiredSeries').count).to eq(2)
        expect(Version.where(item_type: 'RequiredSeries').first.attributes)
          .to include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_1'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version.created_at.as_json],
                  'updated_at' => [nil, version.created_at.as_json]
                ),
                'created_at' => version.created_at,
                'study_id' => study.id
              )
        expect(Version.where(item_type: 'RequiredSeries').last.attributes)
          .to include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_2'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version.created_at.as_json],
                  'updated_at' => [nil, version.created_at.as_json]
                ),
                'created_at' => version.created_at,
                'study_id' => study.id
              )
      end
    end

    describe 'for `update` visit version changing visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }

      let!(:version1) do
        Timecop.travel(Time.local(2017, 6, 4, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: visit.id,
          event: 'create',
          object: nil,
          object_changes: {
            'patient_id' => [nil, patient.id],
            'visit_number' => [nil, '0001'],
            'visit_type' => [nil, 'baseline']
          },
          study_id: study.id
        )
      end
      let!(:version2) do
        Timecop.travel(Time.local(2017, 6, 5, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: visit.id,
          event: 'create',
          object: JSON.parse(visit.to_json),
          object_changes: {
            'visit_type' => ['baseline', 'followup']
          },
          study_id: study.id
        )
      end

      before(:each) do
        # We need to reload so that the dates are of the correct
        # precision. When the object is created by ActiveRecord, the
        # date has a precision to the 8th decimal place, but postgres
        # only saves 5 decimal places.
        version1.reload
        version2.reload
        # Required series are created automatically. To have a clean
        # state we have to remove them first.
        visit.required_series.destroy_all
        Migration::MigrateRequiredSeriesPresets.run
      end

      it 'removes invalidated required series presets' do
        expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
          .to include(include(
                'event' => 'destroy',
                'object' => include('name' => 'SPECT_2')
              ))
      end
      it 'creates required series presets' do
        expect(RequiredSeries.where(visit: visit).count).to eq(2)
      end
      it 'creates required series preset versions' do
        expect(Version.where(item_type: 'RequiredSeries').count).to eq(4)
        expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
          .to include(include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_1'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version1.created_at.as_json],
                  'updated_at' => [nil, version1.created_at.as_json]
                ),
                'created_at' => version1.created_at,
                'study_id' => study.id
              ))
        expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
          .to include(include(
                'item_type' => 'RequiredSeries',
                'event' => 'create',
                'whodunnit' => nil,
                'object_changes' => include(
                  'name' => [nil, 'SPECT_3'],
                  'visit_id' => [nil, visit.id],
                  'created_at' => [nil, version2.created_at.as_json],
                  'updated_at' => [nil, version2.created_at.as_json]
                ),
                'created_at' => version2.created_at,
                'study_id' => study.id
              ))
      end
    end

    describe 'for `update` visit version removing visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }

      let!(:version1) do
        Timecop.travel(Time.local(2017, 6, 4, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: visit.id,
          event: 'update',
          object: JSON.parse(visit.to_json),
          object_changes: {
            'visit_type' => ['baseline', nil]
          },
          study_id: study.id
        )
      end

      before(:each) do
        # We need to reload so that the dates are of the correct
        # precision. When the object is created by ActiveRecord, the
        # date has a precision to the 8th decimal place, but postgres
        # only saves 5 decimal places.
        version1.reload
        Migration::MigrateRequiredSeriesPresets.run
      end

      it 'removes invalidated required series presets' do
        expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
          .to include(include(
                        'event' => 'destroy',
                        'object' => include('name' => 'SPECT_1')
                      ))
        expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
          .to include(include(
                        'event' => 'destroy',
                        'object' => include('name' => 'SPECT_2')
                      ))
      end
    end

    describe 'for `destroy` visit version with visit type' do
      let!(:required_series1) { create(:required_series, visit_id: 5, name: 'SPECT_1') }
      let!(:required_series2) { create(:required_series, visit_id: 5, name: 'SPECT_2') }

      let!(:version) do
        Timecop.travel(Time.local(2017, 6, 4, 14, 0, 0))
        Timecop.scale(3600)
        Version.create!(
          item_type: 'Visit',
          item_id: 5,
          event: 'destroy',
          object: {
            'id' => 5,
            'patient_id' => patient.id,
            'visit_number' => '0001',
            'visit_type' => 'baseline',
            'created_at' => Time.now,
            'updated_at' => 1.day.from_now
          },
          object_changes: nil,
          study_id: study.id
        )
      end

      before(:each) do
        Migration::MigrateRequiredSeriesPresets.run
      end

      it 'removes associated required series presets' do
        expect(RequiredSeries.count).to eq(0)
      end
    end
  end

  describe '::study_configuration', paper_trail: true do
    let!(:study) { create(:study) }
    let!(:config1) { <<CONFIG.strip_heredoc }
      visit_types:
        baseline:
          required_series:
            SPECT_1:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:config2) { <<CONFIG.strip_heredoc }
      visit_types:
        baseline:
          required_series:
            SPECT_1:
              tqc: []
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_3:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:config3) { <<CONFIG.strip_heredoc }
      visit_types:
        baseline:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_3:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:time1) { Time.local(2017, 6, 3, 12, 0, 0) } # study has no configurations
    let!(:time2) { Time.local(2017, 6, 4, 12, 0, 0) } # study has one configuration
    let!(:time3) { Time.local(2017, 6, 5, 12, 0, 0) } # study has two configurations
    let!(:time4) { Time.local(2017, 6, 6, 12, 0, 0) } # study is locked
    let!(:time5) { Time.local(2017, 6, 7, 12, 0, 0) } # study has three configurations, but is locked at config2
    let!(:time6) { Time.local(2017, 6, 8, 12, 0, 0) } # study is unlocked, at config3

    before(:each) do
      Timecop.travel(time1)
      Timecop.scale(3600)
      study.update_configuration!(config1)
      Timecop.travel(time2)
      Timecop.scale(3600)
      study.update_configuration!(config2)
      Timecop.travel(time3)
      Timecop.scale(3600)
      study.lock_configuration!
      Timecop.travel(time4)
      Timecop.scale(3600)
      study.update_configuration!(config3)
      Timecop.travel(time5)
      Timecop.scale(3600)
      study.unlock_configuration!
      Timecop.return
    end

    it 'returns the configuration in history' do
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time1)).to eq(nil)
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time2)).to eq(YAML.load(config1))
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time3)).to eq(YAML.load(config2))
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time4)).to eq(YAML.load(config2))
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time5)).to eq(YAML.load(config2))
      expect(Migration::MigrateRequiredSeriesPresets.study_configuration(study.id, time6)).to eq(YAML.load(config3))
    end
  end
end

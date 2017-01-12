# coding: utf-8
RSpec.describe HistoricReportQuery do
  describe '#current_count' do
    let!(:query) do
      HistoricReportQuery.create(resource_type: 'Visit', group_by: 'state')
    end

    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit1) { create(:visit, patient: patient, state: 0) }
    let!(:visit2) { create(:visit, patient: patient, state: 1) }
    let!(:visit3) { create(:visit, patient: patient, state: 2) }
    let!(:visit4) { create(:visit, patient: patient, state: 2) }

    let!(:count) { query.current_count(study.id) }

    it 'counts the total' do
      expect(count).to include(total: 4)
    end

    it 'counts the groups' do
      expect(count[:group]).to be_a(Hash)
      expect(count[:group]).to include('0' => 1)
      expect(count[:group]).to include('1' => 1)
      expect(count[:group]).to include('2' => 2)
    end
  end

  describe '#entry_values' do
    let!(:query) { HistoricReportQuery.create(resource_type: 'Patient') }

    it 'returns the correct values' do
      count       = { total: 15 }
      delta       = { total: 1 }
      result = query.entry_values(count, delta)
      expect(result).to include(group: nil, count: 15, delta: 1)
    end

    it 'returns the correct values' do
      count       = { total: 15, group: { new: 3,  succeeded: 10, failed: 2 } }
      delta       = { total: 0,  group: { new: -1, succeeded: +1, failed: 0 } }
      result = query.entry_values(count, delta)
      expect(result).to include(group: 'new',       count: 3,  delta: -1)
      expect(result).to include(group: 'succeeded', count: 10, delta: +1)
    end

    it 'returns the correct values for missing group count' do
      count       = { total: 15, group: { succeeded: 10, failed: 2 } }
      delta       = { total: 0,  group: { new: -1, succeeded: +1, failed: 0 } }
      result      = query.entry_values(count, delta)
      expect(result).to include(group: 'new', count: 0,  delta: -1)
      expect(result).to include(group: 'succeeded', count: 10, delta: +1)
    end
  end

  describe '#apply_delta' do
    let!(:query) { HistoricReportQuery.create(resource_type: 'Patient') }

    describe 'reverse: false' do
      it 'applies total delta' do
        count = { total: 15 }
        delta = { total: -1 }
        expect(query.apply_delta(count, delta)).to eq(total: 14)
      end

      it 'applies group deltas' do
        count       = { total: 15, group: { new: 3,  succeeded: 10, failed: 2 } }
        delta       = { total: 0,  group: { new: -1, succeeded: +1, failed: 0 } }
        expectation = { total: 15, group: { new: 2,  succeeded: 11, failed: 2 } }
        expect(query.apply_delta(count, delta)).to eq(expectation)
      end
    end

    describe 'reverse: true' do
      it 'applies total delta' do
        count = { total: 15 }
        delta = { total: -1 }
        expect(query.apply_delta(count, delta, reverse: true)).to eq(total: 16)
      end

      it 'applies group deltas' do
        count       = { total: 15, group: { new: 3,  succeeded: 10, failed: 2 } }
        delta       = { total: 0,  group: { new: -1, succeeded: +1, failed: 0 } }
        expectation = { total: 15, group: { new: 4,  succeeded:  9, failed: 2 } }
        expect(query.apply_delta(count, delta, reverse: true)).to eq(expectation)
      end
    end
  end

  describe '#calculate_delta' do
    describe 'for ungrouped `Visit` report' do
      let!(:query) do
        HistoricReportQuery.create(resource_type: 'Visit')
      end

      it 'calculates create' do
        version = build(:version, event: 'create')
        expect(query.calculate_delta(version)).to eq(total: +1)
      end

      it 'calculates destroy' do
        version = build(:version, event: 'destroy')
        expect(query.calculate_delta(version)).to eq(total: -1)
      end

      it 'ignores update' do
        version = build(:version, event: 'update')
        expect(query.calculate_delta(version)).to eq(nil)
      end
    end

    describe 'for `Visit` report grouped by `state`' do
      let!(:query) do
        HistoricReportQuery.create(resource_type: 'Visit', group_by: 'state')
      end

      it 'calculates create' do
        version = build(
          :version,
          event: 'create',
          object_changes: {
            state: [nil, 0]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: +1, group: {'0' => +1})
      end

      it 'calculates destroy' do
        version = build(
          :version,
          event: 'destroy',
          object: {
            state: 0
          }
        )
        expect(query.calculate_delta(version)).to eq(total: -1, group: {'0' => -1})
      end

      it 'calculates update of state column' do
        version = build(
          :version,
          event: 'update',
          object_changes: {
            state: [0, 1]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: 0, group: {'0' => -1, '1' => +1})
      end

      it 'calculates update of state column' do
        version = build(
          :version,
          event: 'update',
          object_changes: {
            visit_number: [123, 321]
          }
        )
        expect(query.calculate_delta(version)).to eq(nil)
      end
    end

    describe 'for ungrouped `RequiredSeries` report' do
      let!(:query) do
        HistoricReportQuery.create(resource_type: 'RequiredSeries')
      end

      it 'calculates create without required series' do
        version = build(
          :version,
          event: 'create',
          object_changes: {
            'required_series' => [nil, {}]
          }
        )
        expect(query.calculate_delta(version)).to be_nil
      end

      it 'calculates create with required series' do
        version = build(
          :version,
          event: 'create',
          object_changes: {
            'required_series' => [
              nil,
              {
                'baseline' => { 'image_series_id' => '1', 'tqc_state' => 0 }
              }
            ]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: +1)
      end

      it 'calculates destroy without required series' do
        version = build(
          :version,
          event: 'destroy',
          object: {
            'required_series' => {}
          }
        )
        expect(query.calculate_delta(version)).to be_nil
      end

      it 'calculates destroy with required series' do
        version = build(
          :version,
          event: 'destroy',
          object: {
            'required_series' => {
              'baseline' => { 'image_series_id' => '1', 'tqc_state' => 0 }
            }
          }
        )
        expect(query.calculate_delta(version)).to eq(total: -1)
      end

      it 'calculates destroy with two required series' do
        version = build(
          :version,
          event: 'destroy',
          object: {
            'required_series' => {
              'baseline' => { 'image_series_id' => '1', 'tqc_state' => 0 },
              'extra' => { 'image_series_id' => '1', 'tqc_state' => 0 }
            }
          }
        )
        expect(query.calculate_delta(version)).to eq(total: -2)
      end

      it 'calculates update' do
        version = build(
          :version,
          event: 'update',
          object_changes: {
            'required_series' => [
              {},
              {
                'baseline' => { 'image_series_id' => '1', 'tqc_state' => 0 },
                'extra' => { 'image_series_id' => '1', 'tqc_state' => 0 }
              }
            ]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: +2)
      end
    end

    describe 'for `RequiredSeries` report grouped by `tqc_state`' do
      let!(:query) do
        HistoricReportQuery.create(resource_type: 'RequiredSeries', group_by: 'tqc_state')
      end

      it 'calculates create' do
        version = build(
          :version,
          event: 'create',
          object_changes: {
            'required_series' => [
              nil,
              {
                'baseline' => {
                  'image_series_id' => '1',
                  'tqc_state' => 0
                }
              }
            ]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: +1, group: {'0' => +1})
      end

      it 'calculates destroy' do
        version = build(
          :version,
          event: 'destroy',
          object: {
            'required_series' => {
              'baseline' => {
                'image_series_id' => '1',
                'tqc_state' => 0
              }
            }
          }
        )
        expect(query.calculate_delta(version)).to eq(total: -1, group: {'0' => -1})
      end

      it 'calculates update' do
        version = build(
          :version,
          event: 'update',
          object_changes: {
            'required_series' => [
              {
                'baseline' => {
                  'image_series_id' => '1',
                  'tqc_state' => 0
                }
              },
              {
                'baseline' => {
                  'image_series_id' => '1',
                  'tqc_state' => 1
                }
              }
            ]
          }
        )
        expect(query.calculate_delta(version)).to eq(total: 0, group: {'0' => -1, '1' => +1})
      end

      it 'ignores update of irrelevant columns' do
        version = build(
          :version,
          event: 'update',
          object_changes: {
            visit_number: [123, 321]
          }
        )
        expect(query.calculate_delta(version)).to eq(nil)
      end
    end
  end

  describe '#calculate_cache' do
    describe 'for ungrouped resource_type `Patient`' do
      describe 'with empty cache' do
        let(:six_hours_ago) { 6.hours.ago.round }
        let(:four_hours_ago) { 4.hours.ago.round }
        let(:three_hours_ago) { 3.hours.ago.round }
        let(:one_hour_ago) { 1.hour.ago.round }

        before(:each) do
          @study = create(:study)
          Version.last.update_attributes!(created_at: six_hours_ago, updated_at: six_hours_ago)
          center = create(:center, study: @study)
          Version.last.update_attributes!(created_at: six_hours_ago, updated_at: six_hours_ago)
          patient1 = create(:patient, center: center)
          Version.last.update_attributes!(created_at: four_hours_ago, updated_at: four_hours_ago)
          create(:patient, center: center)
          Version.last.update_attributes!(created_at: three_hours_ago, updated_at: three_hours_ago)
          patient1.destroy
          Version.last.update_attributes!(created_at: one_hour_ago, updated_at: one_hour_ago)
        end

        it 'creates full cache' do
          query = HistoricReportQuery.create(resource_type: 'Patient')
          query.calculate_cache(@study.id)
          query.calculate_cache(@study.id)
          entries = HistoricReportCacheEntry.order('"date" ASC').last(3)
          expect(entries[0].date).to eq four_hours_ago
          expect(entries[0].values.length).to eq(1)
          expect(entries[0].values[0]).to eq(group: nil, count: 1, delta: 1)
          expect(entries[1].date).to eq three_hours_ago
          expect(entries[1].values.length).to eq(1)
          expect(entries[1].values[0]).to eq(group: nil, count: 2, delta: 1)
          expect(entries[2].date).to eq one_hour_ago
          expect(entries[2].values.length).to eq(1)
          expect(entries[2].values[0]).to eq(group: nil, count: 1, delta: -1)
        end
      end

      describe 'with existing cache values' do
        let(:six_hours_ago) { 6.hours.ago.round }
        let(:four_hours_ago) { 4.hours.ago.round }
        let(:three_hours_ago) { 3.hours.ago.round }
        let(:one_hour_ago) { 1.hour.ago.round }

        before(:each) do
          @study = create(:study)
          Version.last.update_attributes!(created_at: six_hours_ago, updated_at: six_hours_ago)
          center = create(:center, study: @study)
          Version.last.update_attributes!(created_at: six_hours_ago, updated_at: six_hours_ago)
          patient1 = create(:patient, center: center)
          Version.last.update_attributes!(created_at: four_hours_ago, updated_at: four_hours_ago)
          create(:patient, center: center)
          Version.last.update_attributes!(created_at: three_hours_ago, updated_at: three_hours_ago)
          patient1.destroy
          Version.last.update_attributes!(created_at: one_hour_ago, updated_at: one_hour_ago)
        end

        it 'completes the full cache' do
          query = HistoricReportQuery.create(resource_type: 'Patient')
          HistoricReportCacheEntry.ensure_cache_entry(
            query,
            @study.id,
            three_hours_ago,
            [{ group: nil, count: 2, delta: 1 }]
          )
          query.calculate_cache(@study.id)
          query.calculate_cache(@study.id)
          entries = HistoricReportCacheEntry.order(:date).last(3)
          expect(entries[0].date).to eq four_hours_ago
          expect(entries[0].values.length).to eq(1)
          expect(entries[0].values[0]).to eq(group: nil, count: 1, delta: 1)
          expect(entries[1].date).to eq three_hours_ago
          expect(entries[1].values.length).to eq(1)
          expect(entries[1].values[0]).to eq(group: nil, count: 2, delta: 1)
          expect(entries[2].date).to eq one_hour_ago
          expect(entries[2].values.length).to eq(1)
          expect(entries[2].values[0]).to eq(group: nil, count: 1, delta: -1)
        end
      end
    end

    describe 'for resource_type `Visit` grouped by `state`' do
      describe 'with empty cache' do
        before(:each) do
          @study = create(:study)
          center = create(:center, study: @study)
          patient = create(:patient, center: center)
          @visit1 = create(:visit, patient: patient)
          @version1 = Version.last
          @visit2 = create(:visit, patient: patient)
          @version2 = Version.last
          @visit2.state += 1
          @visit2.save
          @version3 = Version.last
          @visit3 = create(:visit, patient: patient)
          @version4 = Version.last
          @visit3.state += 1
          @visit3.save
          @version5 = Version.last
          @visit4 = create(:visit, patient: patient)
          @version6 = Version.last
          @visit2.state += 1
          @visit2.save
          @version7 = Version.last
        end

        it 'creates full cache' do
          query = HistoricReportQuery.create(
            resource_type: 'Visit',
            group_by: 'state'
          )
          query.calculate_cache(@study.id)
          query.calculate_cache(@study.id)
          expect(query.cache_entries.count).to eq(7)
          entries = HistoricReportCacheEntry.order('"date" ASC').last(7)
          expect(entries[0].date).to eq @version1.created_at
          expect(entries[0].values).to include(group: nil, count: 1, delta: +1)
          expect(entries[0].values).to include(group: '0', count: 1, delta: +1)
          expect(entries[0].values).not_to include(group: '1', count: 0, delta: 0)
          expect(entries[1].date).to eq @version2.created_at
          expect(entries[1].values).to include(group: nil, count: 2, delta: +1)
          expect(entries[1].values).to include(group: '0', count: 2, delta: +1)
          expect(entries[1].values).not_to include(group: '1', count: 0, delta: 0)
          expect(entries[2].date).to eq @version3.created_at
          expect(entries[2].values).not_to include(group: nil, count: 2, delta: 0)
          expect(entries[2].values).to include(group: '0', count: 1, delta: -1)
          expect(entries[2].values).to include(group: '1', count: 1, delta: +1)
          expect(entries[3].date).to eq @version4.created_at
          expect(entries[3].values).to include(group: nil, count: 3, delta: +1)
          expect(entries[3].values).to include(group: '0', count: 2, delta: +1)
          expect(entries[3].values).not_to include(group: '1', count: 1, delta: 0)
          expect(entries[4].date).to eq @version5.created_at
          expect(entries[4].values).not_to include(group: nil, count: 3, delta: 0)
          expect(entries[4].values).to include(group: '0', count: 1, delta: -1)
          expect(entries[4].values).to include(group: '1', count: 2, delta: +1)
          expect(entries[5].date).to eq @version6.created_at
          expect(entries[5].values).to include(group: nil, count: 4, delta: +1)
          expect(entries[5].values).to include(group: '0', count: 2, delta: +1)
          expect(entries[5].values).not_to include(group: '1', count: 2, delta: 0)
          expect(entries[6].date).to eq @version7.created_at
          expect(entries[6].values).not_to include(group: nil, count: 4, delta: 0)
          expect(entries[6].values).not_to include(group: '0', count: 2, delta: 0)
          expect(entries[6].values).to include(group: '1', count: 1, delta: -1)
          expect(entries[6].values).to include(group: '2', count: 1, delta: +1)
        end
      end
    end

    describe 'for ungrouped resource_type `RequiredSeries`' do
      describe 'with empty cache' do
        before(:each) do
          @study = create(:study)
          @center = create(:center, study: @study)
          @patient = create(:patient, center: @center)
          @image_series1 = create(:image_series, patient: @patient)
          @image_series2 = create(:image_series, patient: @patient)
          @visit = create(:visit, patient: @patient)
          @version1 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.assigned_image_series_index = {
            @image_series1.id.to_s => ['baseline']
          }
          @visit.save
          @version2 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 0
            },
            'extra' => {
              'image_series_id' => @image_series2.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.assigned_image_series_index = {
            @image_series1.id.to_s => ['baseline'],
            @image_series2.id.to_s => ['extra']
          }
          @visit.save
          @version3 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 1
            },
            'extra' => {
              'image_series_id' => @image_series2.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.save
          @version4 = Version.last
          @visit.destroy
          @version5 = Version.last
        end

        it 'creates full cache' do
          query = HistoricReportQuery.create(resource_type: 'RequiredSeries')
          query.calculate_cache(@study.id)
          query.calculate_cache(@study.id)
          entries = HistoricReportCacheEntry.order('"date" ASC').last(3)
          expect(entries.length).to eq(3)
          expect(entries[0].date).to eq @version2.created_at
          expect(entries[0].values).to include(group: nil, count: 1, delta: 1)
          expect(entries[1].date).to eq @version3.created_at
          expect(entries[1].values).to include(group: nil, count: 2, delta: 1)
          expect(entries[2].date).to eq @version5.created_at
          expect(entries[2].values).to include(group: nil, count: 0, delta: -2)
        end
      end
    end

    describe 'for resource_type `RequiredSeries` grouped by `tqc_state`' do
      describe 'with empty cache' do
        before(:each) do
          @study = create(:study)
          @center = create(:center, study: @study)
          @patient = create(:patient, center: @center)
          @image_series1 = create(:image_series, patient: @patient)
          @image_series2 = create(:image_series, patient: @patient)
          @visit = create(:visit, patient: @patient)
          @version1 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.assigned_image_series_index = {
            @image_series1.id.to_s => ['baseline']
          }
          @visit.save
          @version2 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 0
            },
            'extra' => {
              'image_series_id' => @image_series2.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.assigned_image_series_index = {
            @image_series1.id.to_s => ['baseline'],
            @image_series2.id.to_s => ['extra']
          }
          @visit.save
          @version3 = Version.last
          @visit.required_series = {
            'baseline' => {
              'image_series_id' => @image_series1.id.to_s,
              'tqc_state' => 1
            },
            'extra' => {
              'image_series_id' => @image_series2.id.to_s,
              'tqc_state' => 0
            }
          }
          @visit.save
          @version4 = Version.last
          @visit.destroy
          @version5 = Version.last
        end

        it 'creates full cache' do
          query = HistoricReportQuery.create(
            resource_type: 'RequiredSeries',
            group_by: 'tqc_state'
          )
          query.calculate_cache(@study.id)
          query.calculate_cache(@study.id)
          entries = HistoricReportCacheEntry.order('"date" ASC').last(4)
          expect(entries.length).to eq(4)
          expect(entries[0].date).to eq @version2.created_at
          expect(entries[0].values).to include(group: nil, count: 1, delta: +1)
          expect(entries[0].values).to include(group: '0', count: 1, delta: +1)
          expect(entries[1].date).to eq @version3.created_at
          expect(entries[1].values).to include(group: nil, count: 2, delta: +1)
          expect(entries[1].values).to include(group: '0', count: 2, delta: +1)
          expect(entries[2].date).to eq @version4.created_at
          expect(entries[2].values).not_to include(group: nil, count: 2, delta: 0)
          expect(entries[2].values).to include(group: '0', count: 1, delta: -1)
          expect(entries[2].values).to include(group: '1', count: 1, delta: +1)
          expect(entries[3].date).to eq @version5.created_at
          expect(entries[3].values).to include(group: nil, count: 0, delta: -2)
          expect(entries[3].values).to include(group: '0', count: 0, delta: -1)
          expect(entries[3].values).to include(group: '1', count: 0, delta: -1)
        end
      end
    end
  end
end

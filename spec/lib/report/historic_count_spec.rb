require 'report/historic_count'

describe Report::HistoricCount do
  let!(:study) { create(:study) }
  before(:each) do
    query = HistoricReportQuery.create(
      resource_type: 'Visit',
      group_by: 'state'
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2016, 12, 31, 12, 00),
      study_id: study.id,
      values: [
        { group: nil, count: 1, delta: +1 },
        { group: 0,   count: 1, delta: +1 },
        { group: 1,   count: 0, delta: 0  }
      ]
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2017, 1, 3, 14, 45),
      study_id: study.id,
      values: [
        { group: nil, count: 2, delta: +1 },
        { group: 0,   count: 2, delta: +1 },
        { group: 1,   count: 0, delta: 0  }
      ]
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2017, 1, 8, 11, 15),
      study_id: study.id,
      values: [
        { group: nil, count: 3, delta: +1 },
        { group: 0,   count: 3, delta: +1 },
        { group: 1,   count: 0, delta: 0  }
      ]
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2017, 1, 8, 14, 18),
      study_id: study.id,
      values: [
        { group: nil, count: 4, delta: +1 },
        { group: 0,   count: 4, delta: +1 },
        { group: 1,   count: 0, delta: 0  }
      ]
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2017, 1, 8, 15, 32),
      study_id: study.id,
      values: [
        { group: nil, count: 4, delta: 0 },
        { group: 0,   count: 3, delta: -1 },
        { group: 1,   count: 1, delta: +1  }
      ]
    )
    HistoricReportCacheEntry.create(
      historic_report_query: query,
      date: DateTime.new(2017, 1, 11, 13, 00),
      study_id: study.id,
      values: [
        { group: nil, count: 5, delta: +1 },
        { group: 0,   count: 4, delta: +1 },
        { group: 1,   count: 1, delta: 0  }
      ]
    )
  end

  describe 'grouped by `state`' do
    describe 'with resolution `day`' do
      let!(:report) do
        Report::HistoricCount.new(
          study_id: study.id,
          resource_type: 'Visit',
          group_by: 'state',
          starts_at: 180.days.ago,
          ends_at: DateTime.now,
          resolution: 'day'
        )
      end

      describe '#result' do
        it 'returns correct values' do
          expected_results = {
            datasets: [
              {
                label: :incomplete_na,
                data: [
                  { x: '2016-12-31', y: 1 },
                  { x: '2017-01-03', y: 2 },
                  { x: '2017-01-08', y: 4 },
                  { x: '2017-01-11', y: 4 }
                ]
              }, {
                label: :complete_tqc_passed,
                data: [
                  { x: '2016-12-31', y: 0 },
                  { x: '2017-01-03', y: 0 },
                  { x: '2017-01-08', y: 1 },
                  { x: '2017-01-11', y: 1 }
                ]
              }
            ]
          }
          expect(report.result).to eq(expected_results)
        end
      end
    end

    describe 'with resolution `week`' do
      let!(:report) do
        Report::HistoricCount.new(
          study_id: study.id,
          resource_type: 'Visit',
          group_by: 'state',
          starts_at: 180.days.ago,
          ends_at: DateTime.now,
          resolution: 'week'
        )
      end

      describe '#result' do
        it 'returns correct values' do
          expected_results = {
            datasets: [
              {
                label: :incomplete_na,
                data: [
                  { x: '2016-12-26', y: 1 },
                  { x: '2017-01-02', y: 4 },
                  { x: '2017-01-09', y: 4 }
                ]
              }, {
                label: :complete_tqc_passed,
                data: [
                  { x: '2016-12-26', y: 0 },
                  { x: '2017-01-02', y: 1 },
                  { x: '2017-01-09', y: 1 }
                ]
              }
            ]
          }
          expect(report.result).to eq(expected_results)
        end
      end
    end

    describe 'with resolution `month`' do
      let!(:report) do
        Report::HistoricCount.new(
          study_id: study.id,
          resource_type: 'Visit',
          group_by: 'state',
          starts_at: 180.days.ago,
          ends_at: DateTime.now,
          resolution: 'month'
        )
      end

      describe '#result' do
        it 'returns correct values' do
          expected_results = {
            datasets: [
              {
                label: :incomplete_na,
                data: [
                  { x: '2016-12-01', y: 1 },
                  { x: '2017-01-01', y: 4 }
                ]
              }, {
                label: :complete_tqc_passed,
                data: [
                  { x: '2016-12-01', y: 0 },
                  { x: '2017-01-01', y: 1 }
                ]
              }
            ]
          }
          expect(report.result).to eq(expected_results)
        end
      end
    end
  end
end

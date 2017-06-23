require 'migration/migrate_required_series_changes'

describe Migration::MigrateRequiredSeriesChanges, paper_trail: false do
  describe '::run' do
    describe 'for `update` visit versions with required series' do
      describe 'assigning required series' do
        let!(:visit) { create(:visit) }
        let!(:required_series) { create(:required_series, visit: visit, name: 'SPECT_1') }

        let!(:version1) do
          Version.create!(
            item_type: 'RequiredSeries',
            item_id: required_series.id,
            event: 'create',
            object_changes: {
              'id' => [nil, required_series.id],
              'visit_id' => [nil, visit.id],
              'name' => [nil, 'SPECT_1'],
              'created_at' => [nil, required_series.created_at]
            }
          )
        end
        let!(:version2) do
          Version.create!(
            item_type: 'Visit',
            item_id: visit.id,
            event: 'update',
            object_changes: {
              'required_series' => [
                {}, {
                  'SPECT_1' => {
                    image_series_id: "5",
                    tqc_state: 0
                  }
                }
              ]
            }
          )
        end

        before(:each) do
          Migration::MigrateRequiredSeriesChanges.run
        end

        it 'updates the required series record' do
          required_series.reload
          expect(required_series.image_series_id).to eq(5)
        end
        it 'creates versions for the respective required series update' do
          expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
            .to include(include('object_changes' => include('image_series_id' => [nil, 5], 'tqc_state' => [nil, 'pending'])))
        end
      end

      describe 'updating tqc results' do
        let!(:visit) { create(:visit) }
        let!(:required_series) { create(:required_series, visit: visit, name: 'SPECT_1') }
        let!(:user) { create(:user) }
        let!(:date) { DateTime.new(2017, 6, 3, 12, 34, 17, 344) }

        let!(:version1) do
          Version.create!(
            item_type: 'RequiredSeries',
            item_id: required_series.id,
            event: 'create',
            object_changes: {
              'id' => [nil, required_series.id],
              'visit_id' => [nil, visit.id],
              'name' => [nil, 'SPECT_1'],
              'created_at' => [nil, required_series.created_at]
            }
          )
        end
        let!(:version2) do
          Version.create!(
            item_type: 'RequiredSeries',
            item_id: required_series.id,
            event: 'create',
            object: {
              'id' => required_series.id,
              'visit_id' => visit.id,
              'name' => 'SPECT_1',
              'created_at' => required_series.created_at
            },
            object_changes: {
              'image_series_id' => [nil, 5],
              'tqc_state' => [nil, 'pending']
            }
          )
        end
        let!(:version3) do
          Version.create!(
            item_type: 'Visit',
            item_id: visit.id,
            event: 'update',
            object_changes: {
              'required_series' => [
                {
                  'SPECT_1' => {
                    image_series_id: "5",
                    tqc_state: 0
                  },
                }, {
                  'SPECT_1' => {
                    image_series_id: "5",
                    tqc_state: 2,
                     tqc_results: {
                      'question' => true
                    },
                    tqc_user_id: user.id,
                    tqc_date: date.as_json,
                    tqc_version: nil,
                    tqc_comment: ''
                  }
                }
              ]
            }
          )
        end

        before(:each) do
          Migration::MigrateRequiredSeriesChanges.run
        end

        it 'updates the required series record' do
          required_series.reload
          expect(required_series.attributes)
            .to include(
                  'tqc_state' => 2,
                  'tqc_results' => {
                    'question' => true
                  },
                  'tqc_user_id' => user.id,
                  'tqc_date' => date,
                  'tqc_version' => nil,
                  'tqc_comment' => ''
                )
        end
        it 'creates versions for the respective required series update' do
          expect(Version.where(item_type: 'RequiredSeries').map(&:attributes))
            .to include(
                  include(
                    'object' => include(
                      'id' => required_series.id,
                      'visit_id' => visit.id,
                      'name' => 'SPECT_1',
                      'created_at' => required_series.created_at.as_json,
                      'image_series_id' => 5,
                      'tqc_state' => 'pending'
                    ),
                    'object_changes' => include(
                      'tqc_state' => ['pending', 'passed'],
                      'tqc_results' => [nil, {'question' => true}],
                      'tqc_user_id' => [nil, user.id],
                      'tqc_date' => [nil, date.as_json],
                      'tqc_comment' => [nil, '']
                    )
                  )
                )
        end
      end
    end

    describe '::required_series_versions' do
      let!(:version) do
        Version.create!(
          item_type: 'Visit',
          item_id: 5,
          event: 'update',
          object_changes: {
            'required_series' => [
              {
                'SPECT_1' => {
                  image_series_id: 2,
                  tqc_state: 0
                },
                'SPECT_3' => {
                  image_series_id: 3,
                  tqc_state: 0
                },
              }, {
                'SPECT_1' => {
                  image_series_id: 5,
                  tqc_state: 0
                },
                'SPECT_2' => {
                  image_series_id: 7,
                  tqc_state: 0
                }
              }
            ]
          }
        )
      end

      let!(:required_series_changes) do
        Migration::MigrateRequiredSeriesChanges.required_series_changes(version)
      end

      it 'extracts the changes of required series' do
        expect(required_series_changes).to include(
                                             visit_id: 5,
                                             name: 'SPECT_1',
                                             changes: {
                                               'image_series_id' => [2, 5]
                                             }
                                           )
        expect(required_series_changes).to include(
                                             visit_id: 5,
                                             name: 'SPECT_2',
                                             changes: {
                                               'image_series_id' => [nil, 7],
                                               'tqc_state' => [nil, 'pending']
                                             }
                                           )
        expect(required_series_changes).to include(
                                             visit_id: 5,
                                             name: 'SPECT_3',
                                             changes: {
                                               'image_series_id' => [3, nil],
                                               'tqc_state' => ['pending', nil]
                                             }
                                           )
      end
    end
  end
end

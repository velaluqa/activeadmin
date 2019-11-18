require 'migration/fix_version_object_changes_for_state_columns'

describe Migration::FixVersionObjectChangesForStateColumns, silent_output: true do
  describe '::run' do
    before(:each) do
      @visit_state_version = Version.create(
        item_type: 'Visit',
        item_id: 1,
        event: 'update',
        object: {
          state: 0
        },
        object_changes: {
          state: [0, 'complete_tqc_passed']
        }
      )
      @visit_state_version2 = Version.create(
        item_type: 'Visit',
        item_id: 1,
        event: 'update',
        object: {
          state: 0
        },
        object_changes: {
          state: ['incomplete_na', 'complete_tqc_passed']
        }
      )
      @visit_mqc_state_version = Version.create(
        item_type: 'Visit',
        item_id: 1,
        event: 'update',
        object: {
          mqc_state: 0
        },
        object_changes: {
          mqc_state: [0, 'issues']
        }
      )
      @visit_mqc_state_version2 = Version.create(
        item_type: 'Visit',
        item_id: 1,
        event: 'update',
        object: {
          mqc_state: 0
        },
        object_changes: {
          mqc_state: ['pending', 'issues']
        }
      )
      @image_series_state_version = Version.create(
        item_type: 'ImageSeries',
        item_id: 1,
        event: 'update',
        object: {
          state: 0
        },
        object_changes: {
          state: [0, 'imported']
        }
      )
      @image_series_state_version2 = Version.create(
        item_type: 'ImageSeries',
        item_id: 1,
        event: 'update',
        object: {
          state: 0
        },
        object_changes: {
          state: ['importing', 1]
        }
      )
      Migration::FixVersionObjectChangesForStateColumns.run
      @visit_state_version.reload
      @visit_state_version2.reload
      @visit_mqc_state_version.reload
      @visit_mqc_state_version2.reload
      @image_series_state_version.reload
      @image_series_state_version2.reload
    end

    it 'replaces symbol values in `object_changes` by their indexes' do
      expect(@visit_state_version.object_changes['state']).to eq([0, 1])
      expect(@visit_state_version2.object_changes['state']).to eq([0, 1])
      expect(@visit_mqc_state_version.object_changes['mqc_state']).to eq([0, 1])
      expect(@visit_mqc_state_version2.object_changes['mqc_state']).to eq([0, 1])
      expect(@image_series_state_version.object_changes['state']).to eq([0, 1])
      expect(@image_series_state_version2.object_changes['state']).to eq([0, 1])
    end
  end
end

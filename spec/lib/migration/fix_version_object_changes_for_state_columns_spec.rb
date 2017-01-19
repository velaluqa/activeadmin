require 'migration/fix_version_object_changes_for_state_columns'

describe Migration::FixVersionObjectChangesForStateColumns do
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
      Migration::FixVersionObjectChangesForStateColumns.run
      @visit_state_version.reload
      @visit_mqc_state_version.reload
      @image_series_state_version.reload
    end

    it 'replaces symbol values in `object_changes` by their indexes' do
      expect(@visit_state_version.object_changes.dig2('state', 1)).to eq(1)
      expect(@visit_mqc_state_version.object_changes.dig2('mqc_state', 1)).to eq(1)
      expect(@image_series_state_version.object_changes.dig2('state', 1)).to eq(1)
    end
  end
end

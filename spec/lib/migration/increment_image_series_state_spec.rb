require 'migration/increment_image_series_state'

describe Migration::IncrementImageSeriesState do
  describe '::run' do
    before(:each) do
      ImageSeries.skip_callback(:save, :before, :update_state)
    end
    after(:each) do
      ImageSeries.set_callback(:save, :before, :update_state)
    end
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }
    let!(:visit) { create(:visit, patient: patient) }
    let!(:image_series0) { create(:image_series, visit: visit, patient: patient, state: 0) }
    let!(:image_series1) { create(:image_series, visit: visit, patient: patient, state: 1) }
    let!(:image_series2) { create(:image_series, visit: visit, patient: patient, state: 2) }
    let!(:image_series3) { create(:image_series, visit: visit, patient: patient, state: 3) }
    let!(:image_series) { create(:image_series, visit: visit, patient: patient) }

    before(:each) do
      image_series.update_attributes(state: 1)
      image_series.update_attributes(state: 2)
      image_series.update_attributes(state: 3)

      Migration::IncrementImageSeriesState.run

      image_series.reload
      image_series0.reload
      image_series1.reload
      image_series2.reload
      image_series3.reload
    end

    it 'increments image series states of existing image series' do
      expect(image_series0.state).to eq(1)
      expect(image_series1.state).to eq(2)
      expect(image_series2.state).to eq(3)
      expect(image_series3.state).to eq(4)
      expect(image_series.state).to eq(4)
    end
    it 'increments image series states of image series versions `object`' do
      expect(Version.where(item_type: 'ImageSeries').pluck(:object))
        .to include(
              include(
                'id' => image_series.id,
                'state' => 1
              ),
              include(
                'id' => image_series.id,
                'state' => 2
              ),
              include(
                'id' => image_series.id,
                'state' => 3
              )
            )
    end
    
    it 'increments image series states of image series versions `object_changes`' do
      expect(Version.where(item_type: 'ImageSeries').order(:created_at).pluck(:object_changes))
        .to include(
              include(
                'id' => [nil, image_series0.id],
                'state' => [0, 1]
              ),
              include(
                'id' => [nil, image_series1.id],
                'state' => [0, 2]
              ),
              include(
                'id' => [nil, image_series2.id],
                'state' => [0, 3]
              ),
              include(
                'id' => [nil, image_series3.id],
                'state' => [0, 4]
              ),
              include(
                'state' => [1, 2]
              ),
              include(
                'state' => [2, 3]
              ),
              include(
                'state' => [3, 4]
              )
            )
    end
  end
end

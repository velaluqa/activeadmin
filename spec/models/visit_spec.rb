RSpec.describe Visit do
  describe '#state=' do
    context 'when saving' do
      let!(:visit) { create(:visit) }

      before(:each) do
        visit.state = :complete_tqc_passed
        visit.save
      end

      let!(:version) { Version.last }

      it 'has the new state' do
        visit = Visit.last
        expect(visit.state).to eq(1)
        expect(visit.state_sym).to eq(:complete_tqc_passed)
      end

      it 'saved the correct version object_changes for state' do
        expect(version.object_changes.dig2('state', 1)).to eq(1)
      end
    end
  end

  describe '#mqc_state=' do
    context 'after save' do
      let!(:visit) { create(:visit) }

      before(:each) do
        visit.mqc_state = :issues
        visit.save
      end

      let!(:version) { Version.last }

      it 'has the new mqc_state' do
        visit = Visit.last
        expect(visit.mqc_state).to eq(1)
        expect(visit.mqc_state_sym).to eq(:issues)
      end

      it 'saved the correct version object_changes for mqc_state' do
        expect(version.object_changes.dig2('mqc_state', 1)).to eq(1)
      end
    end
  end

  describe 'scope ::searchable' do
    it 'selects search fields' do
      center = create(:center, code: 'Foo')
      patient = create(:patient, subject_id: 'Bar', center: center)
      visit = create(:visit, patient: patient)
      expect(Visit.joins(patient: :center).searchable.as_json)
        .to eq [{
          'id' => nil,
          'study_id' => visit.patient.center.study_id,
          'study_name' => visit.patient.center.study.name,
          'text' => "FooBar##{visit.visit_number}",
          'result_id' => visit.id,
          'result_type' => 'Visit'
        }]
    end
  end

  describe 'scope ::with_state' do
    let!(:study) { create(:study) }
    let!(:center) { create(:center, study: study) }
    let!(:patient1) { create(:patient, center: center) }
    let!(:visit0) { create(:visit, patient: patient1, state: 0) }
    let!(:visit1) { create(:visit, patient: patient1, state: 1) }
    let!(:visit2) { create(:visit, patient: patient1, state: 2) }
    let!(:visit3) { create(:visit, patient: patient1, state: 3) }
    let!(:visit4) { create(:visit, patient: patient1, state: 4) }

    it 'filters by Fixnum state' do
      expect(Visit.with_state(0)).to include(visit0)
      expect(Visit.with_state(1)).to include(visit1)
      expect(Visit.with_state(2)).to include(visit2)
      expect(Visit.with_state(3)).to include(visit3)
      expect(Visit.with_state(4)).to include(visit4)
    end

    it 'filters by Symbol state' do
      expect(Visit.with_state(:incomplete_na)).to include(visit0)
      expect(Visit.with_state(:complete_tqc_passed)).to include(visit1)
      expect(Visit.with_state(:incomplete_queried)).to include(visit2)
      expect(Visit.with_state(:complete_tqc_pending)).to include(visit3)
      expect(Visit.with_state(:complete_tqc_issues)).to include(visit4)
    end

    it 'filters by String state' do
      expect(Visit.with_state('incomplete_na')).to include(visit0)
      expect(Visit.with_state('complete_tqc_passed')).to include(visit1)
      expect(Visit.with_state('incomplete_queried')).to include(visit2)
      expect(Visit.with_state('complete_tqc_pending')).to include(visit3)
      expect(Visit.with_state('complete_tqc_issues')).to include(visit4)
    end
  end

  describe 'image storage' do
    before(:each) do
      @study = create(:study, id: 1)
      @center = create(:center, id: 1, study: @study)
      @patient = create(:patient, id: 1, center: @center)
      @patient2 = create(:patient, id: 2, center: @center)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/__unassigned'))
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/__unassigned'))
    end

    it 'handles create' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end

    it 'handles update' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit = create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit.patient_id = 2
      visit.save
      expect(File).to exist(ERICA.image_storage_path.join('1/1/2/1'))
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end

    it 'handles destroy' do
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit = create(:visit, id: 1, patient: @patient)
      expect(File).to exist(ERICA.image_storage_path.join('1/1/1/1'))
      visit.destroy
      expect(File).not_to exist(ERICA.image_storage_path.join('1/1/1/1'))
    end
  end

  describe 'scope #by_study_ids' do
    before :each do
      @study1     = create(:study)
      @center11   = create(:center, study: @study1)

      @patient111 = create(:patient, center: @center11)
      @visit1111  = create(:visit, patient: @patient111)
      @visit1112  = create(:visit, patient: @patient111)

      @center12   = create(:center, study: @study1)
      @patient121 = create(:patient, center: @center12)
      @visit1211  = create(:visit, patient: @patient121)
      @visit1212  = create(:visit, patient: @patient121)

      @study2     = create(:study)
      @center21   = create(:center, study: @study2)

      @patient211 = create(:patient, center: @center21)
      @visit2111  = create(:visit, patient: @patient211)
      @visit2112  = create(:visit, patient: @patient211)

      @center22   = create(:center, study: @study2)
      @patient221 = create(:patient, center: @center22)
      @visit2211  = create(:visit, patient: @patient221)
      @visit2212  = create(:visit, patient: @patient221)

      @study3     = create(:study)
      @center31   = create(:center, study: @study3)

      @patient311 = create(:patient, center: @center31)
      @visit3111  = create(:visit, patient: @patient311)
      @visit3112  = create(:visit, patient: @patient311)

      @center32   = create(:center, study: @study3)
      @patient321 = create(:patient, center: @center32)
      @visit3211  = create(:visit, patient: @patient321)
      @visit3212  = create(:visit, patient: @patient321)
    end

    it 'returns the matched visits for a single study' do
      expect(Visit.by_study_ids(@study1.id))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212
        ]
    end

    it 'returns the matched visits by study' do
      expect(Visit.by_study_ids(@study1.id, @study3.id))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212,
          @visit3111, @visit3112, @visit3211, @visit3212
        ]
      expect(Visit.by_study_ids([@study1.id, @study3.id]))
        .to match_array [
          @visit1111, @visit1112, @visit1211, @visit1212,
          @visit3111, @visit3112, @visit3211, @visit3212
        ]
    end
  end

  describe 'versioning' do
    describe 'create' do
      before(:each) do
        @visit = create(:visit)
        @study_id = @visit.study.id
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Visit').last
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'update' do
      before(:each) do
        @visit = create(:visit)
        @study_id = @visit.study.id
        @visit.description = 'New Name'
        @visit.save!
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Visit').last
        expect(version.event).to eq 'update'
        expect(version.study_id).to eq @study_id
      end
    end
    describe 'destroy' do
      before(:each) do
        @visit = create(:visit)
        @study_id = @visit.study.id
        @visit.destroy
      end

      it 'saves the `study_id` to the version' do
        version = Version.where(item_type: 'Visit').last
        expect(version.event).to eq 'destroy'
        expect(version.study_id).to eq @study_id
      end
    end
  end
end

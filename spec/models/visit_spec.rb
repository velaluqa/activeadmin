RSpec.describe Visit do
  describe 'after commit hook handling required series' do
    let!(:study1) { create(:study, :locked, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2:
            tqc:
              - id: fubaz
                label: "Something different from baselin2!"
                type: bool
          SPECT_3:
            tqc:
              - id: modality
                label: "same tqc spec"
                type: bool
      baseline2:
        required_series:
          SPECT_2:
            tqc:
              - id: foobar
                label: "Something different from baseline!"
                type: bool
          SPECT_3:
            tqc:
              - id: modality
                label: "same tqc spec"
                type: bool
          SPECT_4: {}
    image_series_properties: []
CONFIG
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }

    describe 'creating with visit type' do
      let!(:visit) { create(:visit, patient: patient1, visit_type: 'baseline', visit_number: '10000') }

      it 'adds `SPECT_1` and `SPECT_2` to visits required series' do
        expect(visit.required_series_objects.map(&:name)).to include('SPECT_1', 'SPECT_2')
      end
    end

    describe 'setting visit type' do
      let!(:visit) { create(:visit, patient: patient1, visit_type: nil, visit_number: '10000') }

      it 'adds `SPECT_2` and `SPECT_3` to visits required series' do
        expect(visit .required_series_objects.map(&:name)).not_to include('SPECT_1', 'SPECT_2', 'SPECT_3', 'SPECT_4')
        visit.visit_type = 'baseline2'
        visit.save!
        expect(visit .required_series_objects.map(&:name)).not_to include('SPECT_1')
        expect(visit.required_series_objects.map(&:name)).to include('SPECT_2', 'SPECT_3', 'SPECT_4')
      end
    end

    describe 'changing visit type' do
      let!(:visit) { create(:visit, patient: patient1, visit_type: 'baseline', visit_number: '10000') }

      before(:each) do
        visit.visit_type = 'baseline2'
        visit.save!
      end

      it 'removes `SPECT_1` from visits required series' do
        expect(visit.required_series_objects.map(&:name)).not_to include('SPECT_1')
      end

      it 'keeps same required series' do
        expect(visit.required_series_objects.map(&:name)).to include('SPECT_2', 'SPECT_3')
      end

      it 'adds `SPECT_4` to visits required series' do
        expect(visit.required_series_objects.map(&:name)).to include('SPECT_4')
      end
    end

    describe 'changing visit type for performed tqc' do
      let!(:visit) { create(:visit, patient: patient1, visit_type: 'baseline', visit_number: '10000') }
      let!(:user) { create(:user) }
      let!(:series1) { create(:image_series, visit: visit) }
      let!(:series2) { create(:image_series, visit: visit) }
      let!(:spect_2) { RequiredSeries.where(visit: visit, name: 'SPECT_2').first }
      let!(:spect_3) { RequiredSeries.where(visit: visit, name: 'SPECT_3').first }

      before(:each) do
        spect_2.assign_image_series!(series1)
        spect_2.set_tqc_result({ 'fubaz' => true }, user, 'First tqc')
        spect_3.assign_image_series!(series2)
        spect_3.set_tqc_result({ 'modality' => true }, user, 'First tqc')
        expect(visit.required_series_objects.map(&:tqc_state)).to eq([nil, 'passed', 'passed'])
        visit.visit_type = 'baseline2'
        visit.save!
        spect_2.reload
        spect_3.reload
      end

      it 'keeps tqc results if tqc specifications stay the same' do
        expect(spect_3.tqc_state).to eq('passed')
        expect(spect_3.tqc_user_id).to eq(user.id)
        expect(spect_3.tqc_results).to eq('modality' => true)
        expect(spect_3.tqc_comment).to eq('First tqc')
      end

      it 'resets tqc results if tqc specifications change' do
        expect(spect_2.tqc_state).to eq('pending')
        expect(spect_2.tqc_user_id).to be_nil
        expect(spect_2.tqc_date).to be_nil
        expect(spect_2.tqc_version).to be_nil
        expect(spect_2.tqc_results).to be_nil
        expect(spect_2.tqc_comment).to be_nil
      end
    end

    describe 'removing visit type' do
      let!(:visit) { create(:visit, patient: patient1, visit_type: 'baseline', visit_number: '10000') }

      before(:each) do
        visit.visit_type = nil
        visit.save!
      end

      it 'removes all required series for visit' do
        expect(visit.required_series_objects.map(&:name)).not_to include('SPECT_1', 'SPECT_2', 'SPECT_3', 'SPECT_4')
      end
    end
  end

  describe '#required_series_spec' do
    describe 'for building study' do
      let!(:study) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
    image_series_properties: []
CONFIG
      let!(:center) { create(:center, study: study) }
      let!(:patient) { create(:patient, center: center) }
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
      before(:each) { expect(visit.study.state).to eq(:building) }

      it 'returns includes spec' do
        expect(visit.required_series_spec).to include('SPECT_1' => {}, 'SPECT_2' => {})
        end
    end

    describe 'for semantically invalid study' do
      let!(:study) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
CONFIG
      let!(:center) { create(:center, study: study) }
      let!(:patient) { create(:patient, center: center) }
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
      before(:each) do
        study.lock_configuration!
        expect(visit.study.semantically_valid?).to be_falsy
      end

      it 'returns empty hash' do
        expect(visit.required_series_spec).to eq({})
      end
    end

    describe 'for visit_type = nil' do
      let!(:study) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
    image_series_properties: []
CONFIG
      let!(:center) { create(:center, study: study) }
      let!(:patient) { create(:patient, center: center) }
      let!(:visit) { create(:visit, patient: patient) }
      before(:each) do
        study.lock_configuration!
      end

      it 'returns empty hash' do
        expect(visit.required_series_spec).to eq({})
      end
    end

    describe 'for valid production study' do
      let!(:study) { create(:study) }
      let!(:center) { create(:center, study: study) }
      let!(:patient) { create(:patient, center: center) }
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }

      before(:each) do
        study.update_configuration!(<<CONFIG.strip_heredoc)
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
    image_series_properties: []
CONFIG
        study.lock_configuration!
      end

      let(:current_ref) { study.update_configuration!(<<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
          foobar: {}
    image_series_properties: []
CONFIG

      it 'defaults to locked study version specification for visits visit type' do
        expect(visit.required_series_spec).to be_a(Hash)
        expect(visit.required_series_spec).to include('SPECT_1' => {}, 'SPECT_2' => {})
        expect(visit.required_series_spec).not_to include('foobar' => {})
      end

      describe 'given a :version option' do
        it 'returns specific study specification for visits visit type' do
          expect(visit.required_series_spec(version: current_ref)).to include('SPECT_1' => {}, 'SPECT_2' => {}, 'foobar' => {})
        end
      end
    end
  end

  describe '#clean_required_series!' do
    it 'removes invalid required series that do not match spec from study configuration'
  end

  describe '#required_series_names' do
    let!(:study) { create(:study, :locked, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
    image_series_properties: []
CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }

    describe 'for visit without visit type' do
      let!(:visit) { create(:visit, patient: patient) }
      it 'returns empty array' do
        expect(visit.required_series_names).to eq([])
      end
    end
    describe 'for visit with invalid visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline_invalid') }
      it 'returns empty array' do
        expect(visit.required_series_names).to eq([])
      end
    end
    describe 'for visit with valid visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
      it 'returns word array of required series' do
        expect(visit.required_series_names).to eq(%w(SPECT_1 SPECT_2))
      end
    end
  end

  describe '#required_series_objects' do
    let!(:study) { create(:study, :locked, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1: {}
          SPECT_2: {}
    image_series_properties: []
CONFIG
    let!(:center) { create(:center, study: study) }
    let!(:patient) { create(:patient, center: center) }

    describe 'for visit without visit type' do
      let!(:visit) { create(:visit, patient: patient) }
      it 'returns empty array' do
        expect(visit.required_series_objects.map(&:name)).to eq([])
      end
    end
    describe 'for visit with invalid visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline_invalid') }
      it 'returns empty array' do
        expect(visit.required_series_objects.map(&:name)).to eq([])
      end
    end
    describe 'for visit with valid visit type' do
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
      it 'returns word array of required series' do
        expect(visit.required_series_objects.map(&:name)).to eq(%w(SPECT_1 SPECT_2))
      end
    end
  end

  describe '#change_required_series_assignment' do
    let!(:study1) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT_1:
            tqc: []
          SPECT_2:
            tqc: []
      baseline2:
        required_series:
          SPECT_2:
            tqc: []
          SPECT_3:
            tqc: []
    image_series_properties: []
CONFIG
    before(:each) do
      study1.lock_configuration!
    end

    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:visit1) { create(:visit, patient: patient1, visit_type: 'baseline') }
    let!(:image_series1) { create(:image_series, state: 1, patient: patient1, visit: visit1) }
    let!(:image_series2) { create(:image_series, state: 1, patient: patient1, visit: visit1) }

    describe 'adding assignment for required series' do
      before(:each) do
        visit1.change_required_series_assignment('SPECT_1' => image_series1.id)
      end
      it 'assigns new required series' do
        expect(visit1.required_series_objects.map(&:image_series_id)).to include(image_series1.id)
      end
      it 'sets image series state of assigned image series to `required_series_assigned`' do
        image_series1.reload
        expect(image_series1.state_sym).to eq(:required_series_assigned)
      end
    end

    describe 'changing assignment for required series' do
      before(:each) do
        visit1.change_required_series_assignment('SPECT_1' => image_series1.id)
        visit1.set_tqc_result('SPECT_1', {}, create(:user), '')
        expect(visit1.required_series_objects.find { |rs| rs.name == 'SPECT_1' }.tqc_state).to eq('passed')
        visit1.change_required_series_assignment('SPECT_1' => image_series2.id)
      end

      it 'assigns new required series' do
        expect(visit1.required_series_objects.map(&:image_series_id)).not_to include(image_series1.id)
        expect(visit1.required_series_objects.map(&:image_series_id)).to include(image_series2.id)
      end
      it 'sets image series state of assigned image series to `required_series_assigned`' do
        image_series2.reload
        expect(image_series2.state_sym).to eq(:required_series_assigned)
      end
      it 'sets image series state of unassigned image series to `visit_assigned`' do
        image_series1.reload
        expect(image_series1.state_sym).to eq(:visit_assigned)
      end
      it 'resets `tqc_state` to `pending`' do
        expect(visit1.required_series_objects.find { |rs| rs.name == 'SPECT_1' }.tqc_state).to eq('pending')
      end
    end

    describe 'removing assignment for required series' do
      before(:each) do
        visit1.change_required_series_assignment('SPECT_1' => image_series1.id)
        visit1.change_required_series_assignment('SPECT_1' => nil)
      end

      it 'removes required series assignment' do
        expect(visit1.required_series_objects.map(&:image_series_id)).not_to include(image_series1.id)
      end
      it 'sets image series state of unassigned image series to `visit_assigned`' do
        image_series1.reload
        expect(image_series1.state_sym).to eq(:visit_assigned)
      end
    end
  end

  describe '#assign_required_series' do
    it 'creates new RequiredSeries for the new assignment'
    it 'sets image series state of assigned image series to `required_series_assigned`'
  end

  describe '#reassign_required_series' do
    it 'updates the RequiredSeries image_series'
    it 'sets image series state of assigned image series to `required_series_assigned`'
    it 'sets image series state of unassigned image series to `visit_assigned`'
  end

  describe '#unassign_required_series' do
    it 'removes RequiredSeries relation of the assignment'
    it 'sets image series state of unassigned image series to `visit_assigned`'
  end

  describe '#visit_type_valid?' do
    let!(:study1) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT1: {}
          SPECT2: {}
CONFIG
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:visit1) { create(:visit, patient: patient1, visit_type: nil) }
    let!(:visit2) { create(:visit, patient: patient1, visit_type: 'foobar') }
    let!(:visit3) { create(:visit, patient: patient1, visit_type: 'baseline') }

    it 'returns false if no visit type set' do
      expect(visit1.visit_type_valid?).to be_falsy
    end

    it 'returns false if visit type is not found in study configuration' do
      expect(visit2.visit_type_valid?).to be_falsy
    end

    it 'returns true if visit type in study configuration' do
      expect(visit3.visit_type_valid?).to be_truthy
    end
  end

  describe '#required_series_available?' do
    let!(:study1) { create(:study, configuration: <<CONFIG.strip_heredoc) }
    visit_types:
      baseline:
        required_series:
          SPECT1: {}
          SPECT2: {}
      followup:
        required_series: {}
    image_series_properties: []
CONFIG
    let!(:center1) { create(:center, study: study1) }
    let!(:patient1) { create(:patient, center: center1) }
    let!(:visit1) { create(:visit, patient: patient1, visit_type: nil) }
    let!(:visit2) { create(:visit, patient: patient1, visit_type: 'foobar') }
    let!(:visit3) { create(:visit, patient: patient1, visit_type: 'followup') }
    let!(:visit4) { create(:visit, patient: patient1, visit_type: 'baseline') }

    before(:each) do
      study1.lock_configuration!
    end

    it 'returns false if no visit type set' do
      expect(visit1.required_series_available?).to be_falsy
    end

    it 'returns false if visit type is invalid' do
      expect(visit2.required_series_available?).to be_falsy
    end

    it 'returns false if no required series configured for visit type' do
      expect(visit3.required_series_available?).to be_falsy
    end

    it 'returns true if required series configured for visit type' do
      expect(visit4.required_series_available?).to be_truthy
    end
  end

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

require 'record_search'

describe RecordSearch do
  describe '#new' do
    before(:each) do
      @user = create(:user)
      @search = RecordSearch.new(
        user: @user,
        query: 'foo',
        models: %w(Notification BackgroundJob Study Center Patient Visit ImageSeries Image)
      )
    end

    it 'initializes user, query and only allowed models' do
      expect(@search.user).to eq @user
      expect(@search.query).to eq 'foo'
      expect(@search.models).to eq %w(BackgroundJob Study Center Patient Visit ImageSeries Image)
    end
  end

  describe '#results' do
    before(:each) do
      @study = create(:study, name: 'TestStudy')
      @center = create(:center, code: 'TestCenter', study: @study)
      @patient = create(:patient, subject_id: 'TestPatient', center: @center)
      @visit = create(:visit, visit_number: 2, patient: @patient)
      @user = create(:user, is_root_user: true)
    end

    describe 'not filtering models' do
      before(:each) do
        @search = RecordSearch.new(
          user: @user,
          query: 'Test'
        )
        @results = @search.results
      end

      it 'returns matched records' do
        expect(@results)
          .to include(
                'study_id' => @study.id.to_s,
                'text' => 'TestStudy',
                'result_id' => @study.id.to_s,
                'result_type' => 'Study'
              )
        expect(@results)
          .to include(
                'study_id' => @study.id.to_s,
                'text' => "TestCenter - #{@center.name}",
                'result_id' => @center.id.to_s,
                'result_type' => 'Center'
              )
        expect(@results)
          .to include(
                'study_id' => @study.id.to_s,
                'text' => 'TestCenterTestPatient',
                'result_id' => @patient.id.to_s,
                'result_type' => 'Patient'
              )
        expect(@results)
          .to include(
                'study_id' =>  @study.id.to_s,
                'text'=> "TestCenterTestPatient##{@visit.visit_number}",
                'result_id' => @visit.id.to_s,
                'result_type' => 'Visit'
              )
      end
    end

    describe 'filtering models' do
      before(:each) do
        @search = RecordSearch.new(
          user: @user,
          query: 'Test',
          models: %w(Study)
        )
        @results = @search.results
      end

      it 'returns matched records' do
        expect(@results)
          .to include(
                'study_id' => @study.id.to_s,
                'text' => 'TestStudy',
                'result_id' => @study.id.to_s,
                'result_type' => 'Study'
              )
        expect(@results)
          .not_to include(
                'study_id' => @study.id.to_s,
                'text' => "TestCenter - #{@center.name}",
                'result_id' => @center.id.to_s,
                'result_type' => 'Center'
              )
        expect(@results)
          .not_to include(
                'study_id' => @study.id.to_s,
                'text' => 'TestCenterTestPatient',
                'result_id' => @patient.id.to_s,
                'result_type' => 'Patient'
              )
        expect(@results)
          .not_to include(
                'study_id' =>  @study.id.to_s,
                'text'=> "TestCenterTestPatient##{@visit.visit_number}",
                'result_id' => @visit.id.to_s,
                'result_type' => 'Visit'
              )
      end
    end
  end
end

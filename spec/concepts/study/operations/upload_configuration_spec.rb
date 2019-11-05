describe Study::UploadConfiguration do
  describe 'of configuration removing visit' do
    let!(:study) { create(:study, configuration: <<CONFIG) }
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:temp_file) do
      Tempfile.new.tap do |file|
        file.write(<<CONFIG)
      visit_types:
        baseline:
          required_series: {}
      image_series_properties: []
CONFIG
        file.close
      end
    end
    let!(:params) do
      {
        id: study.id,
        'study_contract_upload_configuration' => {
          id: study.id,
          file: Rack::Test::UploadedFile.new(temp_file.path)
        }
      }
    end

    describe 'with `force` = false' do
      let!(:operation) { Study::UploadConfiguration.(params: params) }

      it 'fails' do
        expect(operation.success?).to be_falsy
      end
    end
    describe 'with `force` = true' do
      let!(:params) do
        {
          id: study.id,
          'study_contract_upload_configuration' => {
            id: study.id,
            file: Rack::Test::UploadedFile.new(temp_file.path),
            force: true
          }
        }
      end
      let!(:operation) { Study::UploadConfiguration.(params: params) }

      it 'succeeds' do
        expect(operation.success?).to be_truthy
      end
    end
  end

  describe 'of configuration removing required series' do
    let!(:study) { create(:study, configuration: <<CONFIG) }
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
CONFIG
    let!(:temp_file) do
      Tempfile.new.tap do |file|
        file.write(<<CONFIG)
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT_1:
              tqc: []
      image_series_properties: []
CONFIG
        file.close
      end
    end
    let!(:params) do
      {
        id: study.id,
        'study_contract_upload_configuration' => {
          id: study.id,
          file: Rack::Test::UploadedFile.new(temp_file.path)
        }
      }
    end

    describe 'with `force` = false' do
      let!(:operation) { Study::UploadConfiguration.(params: params) }

      it 'fails' do
        expect(operation.success?).to be_falsy
      end
    end
    describe 'with `force` = true' do
      let!(:params) do
        {
          id: study.id,
          'study_contract_upload_configuration' => {
            id: study.id,
            file: Rack::Test::UploadedFile.new(temp_file.path),
            force: true
          }
        }
      end
      let!(:operation) { Study::UploadConfiguration.(params: params) }

      it 'succeeds' do
        expect(operation.success?).to be_truthy
      end
    end
  end

  describe 'of invalid configuration' do
    let!(:study) { create(:study) }
    let!(:temp_file) do
      Tempfile.new.tap do |file|
        file.write(<<CONFIG)
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
CONFIG
        file.close
      end
    end
    let!(:params) do
      {
        id: study.id,
        'study_contract_upload_configuration' => {
          id: study.id,
          file: Rack::Test::UploadedFile.new(temp_file.path)
        }
      }
    end
    let!(:operation) { Study::UploadConfiguration.(params: params) }

    it 'fails' do
      expect(operation.success?).to be_falsy
    end
  end

  describe 'of valid configuration' do
    let!(:temp_file) do
      Tempfile.new.tap do |file|
        file.write(<<CONFIG)
      visit_types:
        baseline:
          required_series: {}
        followup:
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
CONFIG
        file.close
      end
    end
    let!(:study) { create(:study) }
    let!(:params) do
      {
        id: study.id,
        'study_contract_upload_configuration' => {
          id: study.id,
          file: Rack::Test::UploadedFile.new(temp_file.path)
        }
      }
    end
    let!(:operation) { Study::UploadConfiguration.(params: params) }

    it 'succeeds' do
      expect(operation.success?).to be_truthy
    end
  end
end

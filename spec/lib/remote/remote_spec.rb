require 'remote/remote'

RSpec.describe Remote do
  before :each do
    stub_request(:get, 'http://localhost:3001/erica_remote/paths.json')
      .to_return(
        body: {
          root: '/srv/ERICA/server',
          data_directory: '/srv/ERICA/server/data',
          form_config_directory: '/srv/ERICA/server/data/forms',
          session_config_directory: '/srv/ERICA/server/data/sessions',
          study_config_directory: '/srv/ERICA/server/data/studies',
          image_storage_directory: '/images'
        }.to_json
      )
    @remote = Remote.new(
      url: 'http://localhost:3001',
      host: 'root@10.0.0.1'
    )
  end

  describe '#working_dir' do
    it 'returns the working dir of the remote sync' do
      expect(@remote.working_dir.to_s)
        .to eq '/srv/ERICA/server/tmp/remote_sync'
    end
  end

  describe 'loading remote paths' do
    describe '#root' do
      it 'returns the correct Pathname' do
        expect(@remote.root).to be_a Pathname
        expect(@remote.root.to_s).to eq '/srv/ERICA/server'
      end
    end
    describe '#data_dir' do
      it 'returns the correct Pathname' do
        expect(@remote.data_dir).to be_a Pathname
        expect(@remote.data_dir.to_s).to eq '/srv/ERICA/server/data'
      end
    end
    describe '#form_config_dir' do
      it 'returns the correct Pathname' do
        expect(@remote.form_config_dir).to be_a Pathname
        expect(@remote.form_config_dir.to_s).to eq '/srv/ERICA/server/data/forms'
      end
    end
    describe '#session_config_dir' do
      it 'returns the correct Pathname' do
        expect(@remote.session_config_dir).to be_a Pathname
        expect(@remote.session_config_dir.to_s).to eq '/srv/ERICA/server/data/sessions'
      end
    end
    describe '#study_config_dir' do
      it 'returns the correct Pathname' do
        expect(@remote.study_config_dir).to be_a Pathname
        expect(@remote.study_config_dir.to_s).to eq '/srv/ERICA/server/data/studies'
      end
    end
    describe '#image_storage_dir' do
      it 'returns the correct Pathname' do
        expect(@remote.image_storage_dir).to be_a Pathname
        expect(@remote.image_storage_dir.to_s).to eq '/images'
      end
    end
  end
end

describe ERICA do
  describe '::remote?' do
    it 'is false if is remote environment' do
      expect(Rails.application.config)
        .to receive(:is_erica_remote).and_return(false)
      expect(ERICA.remote?).to be_falsy
    end

    it 'is true if is remote environment' do
      expect(Rails.application.config)
        .to receive(:is_erica_remote).and_return(true)
      expect(ERICA.remote?).to be_truthy
    end
  end

  describe '::store?' do
    it 'is false if is store environment' do
      expect(Rails.application.config)
        .to receive(:is_erica_remote).and_return(true)
      expect(ERICA.store?).to be_falsy
    end

    it 'is true if is store environment' do
      expect(Rails.application.config)
        .to receive(:is_erica_remote).and_return(false)
      expect(ERICA.store?).to be_truthy
    end
  end

  describe '::data_path' do
    it 'returns relative paths correctly' do
      expect(Rails.application.config)
        .to receive(:data_directory).and_return('data')
      expect(ERICA.data_path).to eq Rails.root.join('data')
    end

    it 'returns absolute paths correctly' do
      expect(Rails.application.config)
        .to receive(:data_directory).and_return('/srv/data')
      expect(ERICA.data_path).to eq Pathname.new('/srv/data')
    end
  end

  describe '::form_config_path' do
    it 'returns relative paths correctly' do
      expect(Rails.application.config)
        .to receive(:form_configs_directory)
        .and_return('data/forms')
      expect(ERICA.form_config_path).to eq Rails.root.join('data', 'forms')
    end

    it 'returns absolute paths correctly' do
      expect(Rails.application.config)
        .to receive(:form_configs_directory)
        .and_return('/srv/data/forms')
      expect(ERICA.form_config_path).to eq Pathname.new('/srv/data/forms')
    end
  end

  describe '::session_config_path' do
    it 'returns relative paths correctly' do
      expect(Rails.application.config)
        .to receive(:session_configs_directory)
        .and_return('data/sessions')
      expect(ERICA.session_config_path).to eq Rails.root.join('data', 'sessions')
    end

    it 'returns absolute paths correctly' do
      expect(Rails.application.config)
        .to receive(:session_configs_directory)
        .and_return('/srv/data/sessions')
      expect(ERICA.session_config_path).to eq Pathname.new('/srv/data/sessions')
    end
  end

  describe '::study_config_path' do
    it 'returns relative paths correctly' do
      expect(Rails.application.config)
        .to receive(:study_configs_directory).and_return('data/studies')
      expect(ERICA.study_config_path).to eq Rails.root.join('data', 'studies')
    end

    it 'returns absolute paths correctly' do
      expect(Rails.application.config)
        .to receive(:study_configs_directory).and_return('/srv/data/studies')
      expect(ERICA.study_config_path).to eq Pathname.new('/srv/data/studies')
    end
  end

  describe '::image_storage_path' do
    it 'returns relative paths correctly' do
      expect(Rails.application.config)
        .to receive(:image_storage_root).and_return('data/images')
      expect(ERICA.image_storage_path).to eq Rails.root.join('data', 'images')
    end

    it 'returns absolute paths correctly' do
      expect(Rails.application.config)
        .to receive(:image_storage_root).and_return('/srv/data/images')
      expect(ERICA.image_storage_path).to eq Pathname.new('/srv/data/images')
    end
  end

  describe '::config_paths' do
    it 'returns configured paths' do
      expect(Rails.application.config).to(receive(:form_configs_directory).and_return('/srv/data/forms'))
      expect(Rails.application.config).to(receive(:session_configs_directory).and_return('/srv/data/sessions'))
      expect(Rails.application.config).to(receive(:study_configs_directory).and_return('/srv/data/studies'))

      expect(ERICA.config_paths.map(&:to_s))
        .to match_array [
          '/srv/data/forms',
          '/srv/data/sessions',
          '/srv/data/studies'
        ]
    end
  end
end

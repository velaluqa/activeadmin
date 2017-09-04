describe PatientReadExportWorker do
  describe '#perform' do
    let(:background_job) { create(:background_job, name: 'Test Patient Read Export') }
    let!(:study) { create(:study, configuration: <<CONFIG.strip_heredoc) }
        visit_types:
          baseline:
            required_series:
              SPECT_1:
                tqc: []
              SPECT_2:
                tqc: []
        image_series_properties: []
CONFIG
    let(:target_path) { ERICA.image_export_path.join(study.name.to_s) }

    describe 'missing patient' do

      before(:each) do
        PatientReadExportWorker.new.perform(background_job.id, study.name.to_s, [23])
      end

      it 'fails with error message' do
        background_job.reload
        expect(background_job.failed?).to be_truthy
        expect(background_job.error_message).to eq('Not all selected patients were found: Couldn\'t find Patient with \'id\'=23')
      end
    end

    describe 'target path exists and is not a directory' do
      before(:each) do
        FileUtils.mkdir_p(target_path.dirname)
        FileUtils.touch(target_path.to_s)
        PatientReadExportWorker.new.perform(background_job.id, study.name.to_s, [23])
      end

      it 'fails with error message' do
        background_job.reload
        expect(background_job.failed?).to be_truthy
        expect(background_job.error_message).to eq("The export target folder #{target_path} exists, but is not a folder.")
      end
    end

    describe 'success' do
      let!(:center) { create(:center, study: study) }
      let!(:patient) { create(:patient, center: center) }
      let!(:visit) { create(:visit, patient: patient, visit_type: 'baseline') }
      let!(:image_series1) { create(:image_series, visit: visit, patient: patient) }
      let!(:image_series2) { create(:image_series, visit: visit, patient: patient) }
      let!(:required_series11) { RequiredSeries.where(visit: visit, name: 'SPECT_1').first.tap { |rs| rs.update_attributes(image_series_id: image_series1.id) } }
      let!(:required_series12) { RequiredSeries.where(visit: visit, name: 'SPECT_2').first.tap { |rs| rs.update_attributes(image_series_id: image_series2.id) } }

      before(:each) do
        PatientReadExportWorker.new.perform(background_job.id, study.name.to_s, [patient.id])
      end

      it 'sets background job to success' do
        background_job.reload
        expect(background_job.failed?).to be_falsy
      end

      it 'creates the patients directories' do
        expect(File).to exist(target_path.join(patient.name))
      end

      it 'creates the visits directories' do
        expect(File).to exist(target_path.join(patient.name).join(visit.visit_number))
      end

      it 'creates required series links' do
        spect1_link = target_path.join(patient.name).join(visit.visit_number).join('SPECT_1')
        expect(File).to exist(spect1_link)
        expect(File.readlink(spect1_link)).to eq("../../../../images/#{image_series1.image_storage_path}")
        spect2_link = target_path.join(patient.name).join(visit.visit_number).join('SPECT_2')
        expect(File).to exist(spect2_link)
        expect(File.readlink(spect2_link)).to eq("../../../../images/#{image_series2.image_storage_path}")
      end

      it 'saves the patients `export_history`' do
        patient.reload
        expect(patient.export_history.last)
          .to include(
                'export_path' => "/app/spec/data/images_export/#{study.name}/#{patient.name}",
                'patient_id' => patient.id,
                'patient_name' => patient.name,
                'visits' => include(
                  include(
                    'visit_id' => visit.id,
                    'visit_number' => visit.visit_number,
                    'export_path' => "/app/spec/data/images_export/#{study.name}/#{patient.name}/#{visit.visit_number}",
                    'required_series' => include(
                      include(
                        'required_series_name' => 'SPECT_1',
                        'assigned_image_series' => image_series1.id,
                        'export_path' => "/app/spec/data/images_export/#{study.name}/#{patient.name}/#{visit.visit_number}/SPECT_1"
                      ),
                      include(
                        'required_series_name' => 'SPECT_2',
                        'assigned_image_series' => image_series2.id,
                        'export_path' => "/app/spec/data/images_export/#{study.name}/#{patient.name}/#{visit.visit_number}/SPECT_2"
                      )
                    )
                  )
                )
              )
      end

      it 'saves the case list to the background job' do
        background_job.reload
        expect(background_job.results['Case List']).
          to eq(<<CASELIST.strip_heredoc)
          patient,images,type
          1211,8,baseline
CASELIST
      end
    end
  end
end

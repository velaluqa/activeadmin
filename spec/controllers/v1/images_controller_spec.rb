require 'spec_helper'

RSpec.describe V1::ImagesController do
  describe '#create' do
    before(:each) do
      image_series = create(:image_series)
      @file = fixture_file_upload('spec/files/test.dicom', 'application/dicom')
      @image_data = {
        image_series_id: image_series.id,
        file: {
          name: 'dicom',
          data: @file
        }
      }
    end

    describe 'without current user' do
      let(:response) { post(:create, format: :json, params: { image: @image_data }) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    describe 'for authorized image_series' do
      login_user_with_abilities do
        can :read, Image
        can :create, Image
      end

      it 'succeeds' do
        response = post(:create, format: :json, params: { image: @image_data })
        expect(response).to have_http_status(:created)
        expect(File).to exist(ERICA.image_storage_path.join(Image.last.image_storage_path))
      end
      
      it 'backups uploaded file in case of error for later investigation' do
        allow_any_instance_of(Image).to receive(:write_anonymized_file).and_raise(StandardError.new('test'))

        response = post(:create, format: :json, params: { image: @image_data })

        expect(response).to have_http_status(:internal_server_error)

        date = "#{Time.now.strftime('%Y%m%d')}"
        time = "#{Time.now.strftime('%H%M%S')}"
        expected_file_path = ERICA.backup_path.join('upload_errors', date, "#{time}_test.dicom").to_s
        
        expect(File).to exist(expected_file_path)       
      end

      it 'fails to save backup file and still destroys image' do
        allow_any_instance_of(Image).to receive(:write_anonymized_file).and_raise(StandardError.new('image storage error'))
        allow_any_instance_of(Image).to receive(:save_error_file).and_raise(StandardError.new('backup error'))

        response = post(:create, format: :json, params: { image: @image_data })

        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json).to include("errors" => include("Error writing file to the image storage: image storage error"))
        expect(Image.count).to eq(0)
      end
    end

    describe 'for unauthorized image_series' do
      login_user_with_abilities do
        can :read, Image
      end

      it 'denies access' do
        response = post(:create, format: :json, params: { image: @image_data })
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

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
      let(:response) { post(:create, format: :json, image: @image_data) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    describe 'for authorized image_series' do
      login_user_with_abilities do
        can :read, Image
        can :create, Image
      end

      it 'succeeds' do
        response = post(:create, format: :json, image: @image_data)
        expect(response).to have_http_status(:created)
        expect(File).to exist(ERICA.image_storage_path.join(Image.last.image_storage_path))
      end
    end

    describe 'for unauthorized image_series' do
      login_user_with_abilities do
        can :read, Image
      end

      it 'denies access' do
        response = post(:create, format: :json, image: @image_data)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

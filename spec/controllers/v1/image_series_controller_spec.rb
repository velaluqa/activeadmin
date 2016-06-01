require 'spec_helper'

RSpec.describe V1::ImageSeriesController do
  describe '#create' do
    let(:image_series) do
      patient = create(:patient)
      {
        name: 'Some Series',
        imaging_date: DateTime.now,
        patient_id: patient.id
      }
    end

    describe 'without current user' do
      let(:response) { post(:create, format: :json, image_series: image_series) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    describe 'for authorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
        can :create, ImageSeries
      end

      it 'succeeds' do
        response = post(:create, format: :json, image_series: image_series)
        expect(response).to have_http_status(:created)
      end
    end

    describe 'for unauthorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
      end

      it 'denies access' do
        response = post(:create, format: :json, image_series: image_series)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#update' do
    before(:each) do
      @image_series = create(:image_series, name: 'Some Series', state: :importing)
      @new_attributes = {
        name: 'My Awesome Series',
        state: 'imported'
      }
    end

    describe 'without current user' do
      let(:response) { put(:update, id: @image_series.id, format: :json, image_series: @new_attributes) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    describe 'for authorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
        can :update, ImageSeries
      end

      it 'succeeds' do
        response = put(:update, id: @image_series.id, format: :json, image_series: @new_attributes)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'for unauthorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
      end

      it 'denies access' do
        response = put(:update, id: @image_series.id, format: :json, image_series: @new_attributes)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#assign_required_series' do
    before(:each) do
      @visit = create(:visit)
      @image_series = create(:image_series, visit: @visit, name: 'Some Series', state: :imported)
      @required_series = ['liver_portal_venous']
    end

    describe 'without current user' do
      let(:response) { post(:assign_required_series, id: @image_series.id, format: :json, required_series: @required_series) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    describe 'for authorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
        can :assign_required_series, Visit
      end

      it 'succeeds' do
        response = post(:assign_required_series, id: @image_series.id, format: :json, required_series: @required_series)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'for unauthorized image_series' do
      login_user_with_abilities do
        can :read, ImageSeries
      end

      it 'denies access' do
        response = post(:assign_required_series, id: @image_series.id, format: :json, required_series: @required_series)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

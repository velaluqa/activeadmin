require 'spec_helper'

RSpec.describe Admin::ImageHierarchyController, type: :controller do
  describe 'without current user' do
    subject { get :index }
    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to('/users/sign_in') }
  end

  render_views

  describe '#index' do
    describe 'for authorized user' do
      login_user_with_abilities do
        can(:read, Study)
        can(:read, Center)
        can(:read, Patient)
        can(:read, Visit)
        can(:read, ImageSeries)
      end

      it 'succeeds' do
        response = get :index
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#nodes' do
    describe 'without current user' do
      subject { get(:nodes, format: :json) }
      it { expect(subject.status).to eq 401 }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can(:read, Study)
        can(:read, Center)
        can(:read, Patient)
        can(:read, Visit)
        can(:read, ImageSeries)
      end
      render_views
      it 'succeeds' do
        response = get(:nodes, format: :json)
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:nodes, format: :json)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

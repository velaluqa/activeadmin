require 'spec_helper'

RSpec.describe Admin::PatientsController do
  describe 'without current user' do
    subject { get :index }
    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to('/users/sign_in') }
  end

  describe '#index' do
    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Patient
      end

      it 'succeeds' do
        response = get :index
        expect(response).to be_success
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

  describe '#show' do
    before(:each) do
      @patient = create(:patient)
    end

    describe 'without current user' do
      subject { get(:show, id: @patient.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Patient
      end

      it 'succeeds' do
        response = get(:show, id: @patient.id)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, id: @patient.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

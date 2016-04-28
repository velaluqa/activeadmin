require 'spec_helper'

RSpec.describe Admin::VisitsController do

  describe '#index' do
    describe 'without current user' do
      subject { get :index }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
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
      @visit = create(:visit)
    end

    describe 'without current user' do
      subject { get(:show, id: @visit.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'succeeds' do
        response = get(:show, id: @visit.id)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, id: @visit.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#new' do
    describe 'without current user' do
      subject { get(:new) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
        can :create, Visit
      end

      it 'succeeds' do
        response = get(:new)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#create' do
    describe 'without current user' do
      subject { post(:create, visit: {}) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
        can :create, Visit
      end

      before(:each) do
        @patient = FactoryGirl.create(:patient)
      end

      it 'succeeds' do
        response = post(:create, visit: {
                          name: 'My New Visit',
                          patient_id: @patient.id,
                          visit_number: 1
                        })
        expect(response).to redirect_to(%r{/admin/visits/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = post(:create, visit: {})
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @visit = create(:visit)
    end

    describe 'without current user' do
      subject { post(:destroy, id: @visit.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
        can :destroy, Visit
      end

      it 'succeeds' do
        response = post(:destroy, id: @visit.id)
        expect(response).to redirect_to('/admin/visits')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = post(:destroy, id: @visit.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

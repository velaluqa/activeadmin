require 'spec_helper'

RSpec.describe Admin::StudiesController, type: :controller do

  describe '#index' do
    describe 'without current user' do
      subject { get :index }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Study
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
      @study = create(:study)
    end

    describe 'without current user' do
      subject { get(:show, id: @study.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Study
      end

      it 'succeeds' do
        response = get(:show, id: @study.id)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, id: @study.id)
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
        can :read, Study
        can :create, Study
      end

      it 'succeeds' do
        response = get(:new)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Study
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

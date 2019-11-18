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
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get :index
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#show' do
    before(:each) do
      @visit = create(:visit)
    end

    describe 'without current user' do
      subject { get(:show, params: { id: @visit.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'succeeds' do
        response = get(:show, params: { id: @visit.id })
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, params: { id: @visit.id })
        expect(response).to redirect_to(admin_not_authorized_path)
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
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#create' do
    describe 'without current user' do
      subject { post(:create, params: {
                       visit: {}
                     }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
        can :create, Visit
      end

      before(:each) do
        @patient = FactoryBot.create(:patient)
      end

      it 'succeeds' do
        response = post(:create, params: {
                          visit: {
                            name: 'My New Visit',
                            patient_id: @patient.id,
                            visit_number: 1
                          }
                        })
        expect(response).to redirect_to(%r{/admin/visits/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = post(:create, params: {
                          visit: {}
                        })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @visit = create(:visit)
    end

    describe 'without current user' do
      subject { post(:destroy, params: { id: @visit.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
        can :destroy, Visit
      end

      it 'succeeds' do
        response = post(:destroy, params: { id: @visit.id })
        expect(response).to redirect_to('/admin/visits')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'denies access' do
        response = post(:destroy, params: { id: @visit.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end
end

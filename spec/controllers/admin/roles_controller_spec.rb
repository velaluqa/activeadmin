require 'spec_helper'

RSpec.describe Admin::RolesController do
  describe '#index' do
    describe 'without current user' do
      subject { get :index }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Role
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
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#show' do
    before(:each) do
      @role = create(:role)
    end

    describe 'without current user' do
      subject { get(:show, id: @role.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Role
      end

      it 'succeeds' do
        response = get(:show, id: @role.id)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, id: @role.id)
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
        can :read, Role
        can :create, Role
      end

      it 'succeeds' do
        response = get(:new)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Role
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#create' do
    describe 'without current user' do
      subject { post(:create, role: {}) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Role
        can :create, Role
      end

      it 'succeeds' do
        response = post(:create, role: { title: 'My New Role' })
        expect(response).to redirect_to(%r{/admin/roles/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Role
      end

      it 'denies access' do
        response = post(:create, role: {})
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @role = create(:role)
    end

    describe 'without current user' do
      subject { post(:destroy, id: @role.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Role
        can :destroy, Role
      end

      it 'succeeds' do
        response = post(:destroy, id: @role.id)
        expect(response).to redirect_to('/admin/roles')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Role
      end

      it 'denies access' do
        response = post(:destroy, id: @role.id)
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end
end

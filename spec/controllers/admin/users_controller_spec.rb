require 'spec_helper'

RSpec.describe Admin::UsersController do
  describe '#index' do
    describe 'without current user' do
      subject { get :index }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, User
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
      @user = create(:user)
    end

    describe 'without current user' do
      subject { get(:show, id: @user.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, User
      end

      it 'succeeds' do
        response = get(:show, id: @user.id)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, id: @user.id)
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
        can :read, User
        can :create, User
      end

      it 'succeeds' do
        response = get(:new)
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, User
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#create' do
    let(:user) do
      {
        username: 'foobar',
        name: 'Foo Bar',
        email: 'foo@baz.de',
        password: 'bazbazbazbaz',
        password_confirmation: 'bazbazbazbaz',
        signature_password: 'fubazfubaz',
        signature_password_confirmation: 'fubazfubaz'
      }
    end

    describe 'without current user' do
      subject { post(:create, user: user) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, User
        can :create, User
      end

      it 'succeeds' do
        response = post(:create, user: user)
        expect(response).to redirect_to(%r{/admin/users/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, User
      end

      it 'denies access' do
        response = post(:create, user: user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @user = create(:user)
    end

    describe 'without current user' do
      subject { post(:destroy, id: @user.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, User
        can :destroy, User
      end

      it 'succeeds' do
        response = post(:destroy, id: @user.id)
        expect(response).to redirect_to('/admin/users')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, User
      end

      it 'denies access' do
        response = post(:destroy, id: @user.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

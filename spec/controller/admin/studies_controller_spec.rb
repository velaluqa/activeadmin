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

  describe '#create' do
    describe 'without current user' do
      subject { post(:create, study: {}) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Study
        can :create, Study
      end

      it 'succeeds' do
        response = post(:create, study: {
                          name: 'My New Study',
                          domino_db_url: '',
                          domino_server_name: ''
                        })
        expect(response).to redirect_to(%r{/admin/studies/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Study
      end

      it 'denies access' do
        response = post(:create, study: {})
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @study = create(:study)
    end

    describe 'without current user' do
      subject { post(:destroy, id: @study.id) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Study
        can :destroy, Study
      end

      it 'succeeds' do
        response = post(:destroy, id: @study.id)
        expect(response).to redirect_to('/admin/studies')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Study
      end

      it 'denies access' do
        response = post(:destroy, id: @study.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#upload_config' do
    before(:each) do
      @study = create(:study)
    end

    let(:file) do
      fixture_file_upload('spec/files/study_configuration_valid.yml', 'text/yml')
    end

    describe 'without current user' do
      let(:response) do
        post(:upload_config, id: @study.id, study: { file: file })
      end

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Study
        can :manage, Study
      end

      let(:response) do
        post(:upload_config, id: @study.id, study: { file: file })
      end

      it { expect(response).to redirect_to(%r{/admin/studies/\d+}) }
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, Study
      end

      let(:response) do
        post(:upload_config, id: @study.id, study: { file: file })
      end

      it { expect(response).to have_http_status(:forbidden) }
    end
  end
end

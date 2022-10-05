require 'spec_helper'

RSpec.describe Admin::BackgroundJobsController do
  describe 'without current user' do
    subject { get :index }
    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to('/users/sign_in') }
  end

  describe '#index' do
    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, BackgroundJob
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
      @background_job = create(:background_job)
    end

    describe 'without current user' do
      subject { get(:show, params: { id: @background_job.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, BackgroundJob
      end

      it 'succeeds' do
        response = get(:show, params: { id: @background_job.id })
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, params: { id: @background_job.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @background_job = create(:background_job, :successful)
    end

    describe 'without current user' do
      subject { post(:destroy, params: { id: @background_job.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, BackgroundJob
        can :destroy, BackgroundJob
      end

      it 'succeeds' do
        response = post(:destroy, params: { id: @background_job.id })
        expect(response).to redirect_to('/admin/background_jobs')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, BackgroundJob
      end

      it 'denies access' do
        response = post(:destroy, params: { id: @background_job.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end
end

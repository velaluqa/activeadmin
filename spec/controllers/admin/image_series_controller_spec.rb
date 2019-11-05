require 'spec_helper'

RSpec.describe Admin::ImageSeriesController do
  describe 'without current user' do
    subject { get :index }
    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to('/users/sign_in') }
  end

  describe '#index' do
    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, ImageSeries
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
      @image_series = create(:image_series)
    end

    describe 'without current user' do
      subject { get(:show, params: { id: @image_series.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, ImageSeries
      end

      it 'succeeds' do
        response = get(:show, params: { id: @image_series.id })
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, params: { id: @image_series.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe 'member_action :viewer' do
    before(:each) do
      @image_series = create(:image_series)
    end

    describe 'without current user' do
      subject { get(:viewer, params: { id: @image_series.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, ImageSeries
      end

      it 'succeeds' do
        response = get(:viewer, params: { id: @image_series.id })
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:viewer, params: { id: @image_series.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end
end

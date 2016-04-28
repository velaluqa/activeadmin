require 'spec_helper'

RSpec.describe Admin::ViewerCartController, type: :controller do
  describe 'without current user' do
    subject { get :index }
    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to('/users/sign_in') }
  end

  render_views

  describe '#index' do
    describe 'for authorized user' do
      login_user_with_abilities do
        can(:manage, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin')
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

  describe '#empty' do
    describe 'without current user' do
      subject { get(:empty) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can(:manage, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin')
      end
      render_views
      it 'succeeds' do
        @request.env['HTTP_REFERER'] = root_url
        response = get(:empty)
        expect(response).to redirect_to(root_url)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:empty)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#clear' do
    describe 'without current user' do
      subject { get(:clear) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can(:manage, ActiveAdmin::Page, name: 'Viewer Cart', namespace_name: 'admin')
      end
      render_views
      it 'succeeds' do
        response = get(:clear)
        expect(response).to redirect_to('/admin/viewer_cart')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:clear)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

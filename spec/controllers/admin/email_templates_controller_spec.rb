require 'spec_helper'

RSpec.describe Admin::EmailTemplatesController do
  describe '#index' do
    describe 'without current user' do
      subject { get :index }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
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
      @email_template = create(:email_template)
    end

    describe 'without current user' do
      subject { get(:show, params: { id: @email_template.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
      end

      it 'succeeds' do
        response = get(:show, params: { id: @email_template.id })
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get(:show, params: { id: @email_template.id })
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
        can :read, EmailTemplate
        can :create, EmailTemplate
      end

      it 'succeeds' do
        response = get(:new)
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
      end

      it 'denies access' do
        response = get(:new)
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#create' do
    describe 'without current user' do
      subject { post(:create, params: { email_template: {} }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
        can :create, EmailTemplate
      end

      it 'succeeds' do
        response = post(:create, params: {
                          email_template: {
                            name: 'My New EmailTemplate',
                            email_type: 'NotificationProfile',
                            template: 'Some Template'
                          }
                        })
        expect(response).to redirect_to(%r{/admin/email_templates/\d+})
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
      end

      it 'denies access' do
        response = post(:create, params: { email_template: {} })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @email_template = create(:email_template)
    end

    describe 'without current user' do
      subject { post(:destroy, params: { id: @email_template.id }) }
      it { expect(subject.status).to eq 302 }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
        can :destroy, EmailTemplate
      end

      it 'succeeds' do
        response = post(:destroy, params: { id: @email_template.id })
        expect(response).to redirect_to('/admin/email_templates')
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
      end

      it 'denies access' do
        response = post(:destroy, params: { id: @email_template.id })
        expect(response).to redirect_to(admin_not_authorized_path)
      end
    end
  end

  describe '#preview' do
    before(:each) do
      @study = create(:study)
    end

    describe 'without current user' do
      subject do
        get(
          :preview,
          params: {
            type: 'NotificationProfile',
            subject: "Study_#{@study.id}",
            template: 'Study: {{notifications.first.resource.name}}'
          }
        )
      end
      it { expect(subject).to have_http_status(:found) }
      it { expect(subject).to redirect_to('/users/sign_in') }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
        can :read, Study
      end

      it 'succeeds' do
        response = get(
          :preview,
          params: {
            type: 'NotificationProfile',
            subject: "Study_#{@study.id}",
            template: 'Study: {{notifications.first.resource.name}}'
          }
        )
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['result']).to include "Study: #{@study.name}"
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities do
        can :read, EmailTemplate
      end

      it 'denies access' do
        response = get(
          :preview,
          params: {
            type: 'NotificationProfile',
            subject: "Study_#{@study.id}",
            template: 'Study: <%= notifications.first.resource.name %>'
          }
        )
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq '{"error":"Access Denied"}'
      end
    end
  end
end

require 'spec_helper'

RSpec.describe V1::VisitsController do
  describe '#index' do
    before(:each) do
      @visit = create(:visit)
    end

    describe 'without current user' do
      subject { get :index, format: :json, params: { patient_id: @visit.patient.id } }
      it { expect(subject).to have_http_status(:forbidden) }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, Visit
      end

      it 'succeeds' do
        response = get :index, format: :json, params: { patient_id: @visit.patient.id }
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    describe 'for unauthorized user' do
      login_user_with_abilities

      it 'denies access' do
        response = get :index, format: :json, params: { patient_id: @visit.patient.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

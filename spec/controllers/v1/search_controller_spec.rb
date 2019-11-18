RSpec.describe V1::SearchController, type: :controller do
  describe '#index' do
    describe 'without current user' do
      subject { get :index, format: :json, params: { query: 'Test' } }
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read, BackgroundJob
        can :read, Study
        can :read, Center
        can :read, Patient
        can :read, Visit
        can :read, ImageSeries
        can :read, Image
      end

      it 'succeeds' do
        response = get :index, format: :json, params: { query: 'Test' }
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end
  end
end

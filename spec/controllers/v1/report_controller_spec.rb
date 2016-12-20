RSpec.describe V1::ReportController do
  describe '#index' do
    describe 'without current user' do
      subject { get(:index, format: :json, type: 'overview', params: { columns: 'all' }) }
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    describe 'for authorized user' do
      login_user_with_abilities do
        can :read_reports, Study
      end

      it 'succeeds' do
        response = get(:index, format: :json, type: 'overview', params: { columns: 'all' })
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end
    end
  end
end

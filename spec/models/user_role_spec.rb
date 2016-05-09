RSpec.describe UserRole do
  before(:each) do
    @user = create(:user)
    @role = create(:role)
    @study = create(:study)
  end

  it 'creates correct scoped role' do
    @user_role = UserRole.create(
      user: @user,
      role: @role,
      scope_object: @study)
    @user_role.reload
    expect(@user_role.scope_object).to eq @study
  end
end

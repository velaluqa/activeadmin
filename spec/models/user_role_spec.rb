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
      scope_object: @study
    )
    @user_role.reload
    expect(@user_role.scope_object).to eq @study
  end

  it 'validates uniqueness of user and role with scope' do
    UserRole.create(user: @user, role: @role, scope_object: @study)
    ur = UserRole.new(user: @user, role: @role, scope_object: @study)
    expect(ur.valid?).to be_falsy
  end

  it 'validates uniqueness of user and role without scope' do
    UserRole.create(user: @user, role: @role)
    ur = UserRole.new(user: @user, role: @role)
    expect(ur.valid?).to be_falsy
  end

  it 'validates uniqueness of user and role with mixed scope' do
    UserRole.create(user: @user, role: @role)
    ur = UserRole.new(user: @user, role: @role, scope_object: @study)
    expect(ur.valid?).to be_truthy
  end
end

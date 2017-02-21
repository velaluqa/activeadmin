step 'a user :string' do |username|
  FactoryGirl.create(:user, username: username)
end

step 'a user :string with :role_instance' do |username, role|
  send('a user :string', username)
  send('user :user_instance belongs to role :role_instance', username, role)
end

step 'a user :string with :role_instance scoped to :model_instance' do |username, role, scope_object|
  send('a user :string', username)
  send('user :user_instance belongs to role :role_instance scoped to :model_instance', username, role, scope_object)
end

step 'user :user_instance belongs to role :role_instance' do |user, role|
  UserRole.create(user: user, role: role)
end

step 'user :user_instance belongs to role :role_instance scoped to :model_instance' do |user, role, scope_object|
  expect(scope_object).to be_present
  UserRole.create(
    user: user,
    role: role,
    scope_object: scope_object
  )
  user_role = user.user_roles.where(role: role).first
  expect(user_role).not_to be_nil
  expect(user_role.scope_object).to eq(scope_object)
end

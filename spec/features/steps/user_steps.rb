step 'a user :string' do |username|
  FactoryGirl.create(
    :user,
    :changed_password,
    :with_keypair,
    username: username
  )
end

step 'a user :string with role :string' do |username, role|
  step("a user \"#{username}\"")
  step("user \"#{username}\" belongs to role \"#{role}\"")
end

step 'a user :string with role :string scoped to :model :instance' do |username, role, model, instance|
  step("a user \"#{username}\"")
  step(
    "user \"#{username}\" belongs to role \"#{role}\" scoped to #{model} \"#{
      instance
    }\""
  )
end

step 'user :user_instance belongs to role :role_instance' do |user, role|
  UserRole.create(user: user, role: role)
end

step 'user :user_instance belongs to role :role_instance scoped to :model_instance' do |user, role, scope_object|
  expect(scope_object).to be_present
  UserRole.create(user: user, role: role, scope_object: scope_object)
  user_role = user.user_roles.where(role: role).first
  expect(user_role).not_to be_nil
  expect(user_role.scope_object).to eq(scope_object)
end

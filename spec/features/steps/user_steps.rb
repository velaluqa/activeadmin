step 'an unconfirmed user :string with:' do |username, attributes|
  FactoryBot.create(
    :user,
    :changed_password,
    :with_keypair,
    :unconfirmed,
    attributes
      .rows_hash
      .symbolize_keys
      .merge(username: username)
  )
end

step 'a user :string' do |username|
  FactoryBot.create(
    :user,
    :changed_password,
    :with_keypair,
    username: username
  )
end

step 'a user :string with:' do |username, attributes|
  FactoryBot.create(
    :user,
    :changed_password,
    :with_keypair,
    attributes
      .rows_hash
      .symbolize_keys
      .merge(username: username)
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
  user_role = user.user_roles.where(
    role: role,
    scope_object_id: scope_object.id
  ).first
  expect(user_role).not_to be_nil
  expect(user_role.scope_object).to eq(scope_object)
end

step 'I change the password of :string to :string' do |username, password|
  step "I browse to \"/admin/users\""
  step "I see \"#{username}\""
  step "I click \"Edit\" in \"#{username}\" row"
  step "I fill in \"Password\" with \"#{password}\""
  step "I fill in \"Password confirmation\" with \"#{password}\""
  step "I click button \"Update User\""
  step "I see \"User was successfully updated\""
end

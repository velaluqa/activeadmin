step 'I sign in as a user' do
  @current_user_role = FactoryGirl.create(:role)
  @current_user = FactoryGirl.create(:user,
                                     name: 'Test User',
                                     username: 'testuser',
                                     password: 'password',
                                     password_changed_at: Time.now,
                                     with_user_roles: [@current_user_role])
  visit('/users/sign_in')
  within('#new_user') do
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
  end
  click_button 'Sign in'
  expect(page).to have_content('Signed in successfully')
end

step 'I sign in as a user with role scoped to :model_instance' do |record|
  send('I sign in as a user')
  send('I have a role scoped to :model_instance', record)
end

step 'I sign in as a user with role :role_instance' do |role|
  send('I sign in as a user')
  send('I belong to role :role_instance', role)
end

step 'I sign in as a user with role :role_instance scoped to :model_instance' do |role, scope_object|
  send('I sign in as a user')
  send('I belong to role :role_instance scoped to :model_instance', role, scope_object)
end

step 'I belong to role :role_instance' do |role|
  send('user :user_instance belongs to role :role_instance', @current_user, role)
end

step 'I belong to role :role_instance scoped to :model_instance' do |role, scope_object|
  send('user :user_instance belongs to role :role_instance scoped to :model_instance', @current_user, role, scope_object)
end

step 'I have a role scoped to :model_instance' do |scope_object|
  @current_user_role = FactoryGirl.create(:role)
  send('user :user_instance belongs to role :role_instance scoped to :model_instance', @current_user, @current_user_role, scope_object)
end

step 'I can :activity :subject' do |activity, subject|
  @current_user_role.add_permission(activity, subject)
end

step 'I cannot :activity :subject' do |activity, subject|
  expect(@current_user.can?(activity, subject)).to be_falsy
end

step 'I browse to :string' do |path|
  visit(path)
end

step 'I browse to :admin_path' do |path|
  visit(path)
end

step 'I see the unauthorized page' do
  expect(page).to have_content('Not authorized')
end

step 'I have following abilities:' do |table|
  table.to_a.each do |subject, activities|
    activities = activities.split(/, ?/)
    activities.each do |activity|
      @current_user_role.add_permission(activity, subject)
    end
  end
end

step 'I see :string' do |content|
  expect(page).to have_content(content)
end

step 'I don\'t see :string' do |content|
  expect(page).not_to have_content(content)
end

step 'I am redirected to patient :string' do |subject_id|
  @patient = Patient.where(subject_id: subject_id).first
  expect(@patient).not_to be_nil
  expect(page.current_path).to eq(admin_patient_path(@patient))
end

step 'I click link :string' do |locator|
  click_link(locator)
end

step 'I click link :string in :string' do |locator, selector|
  within(selector) do
    click_link(locator)
  end
end

step 'I pry' do
  binding.pry
end

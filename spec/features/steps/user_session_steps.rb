placeholder :activity do
  activities = Ability::ACTIVITIES.values.flatten.uniq
  match(/([^ $\n]+)/) do |activity|
    sym = activity.to_sym
    unless activities.include?(sym)
      fail "Activity `#{sym}` not defined in `Ability`"
    end
    sym
  end
end

placeholder :subject do
  match(/([^ $\n]+)/) do |subject|
    subject.classify.constantize
  end
end

placeholder :model do
  match(/([^ $\n]+)/) do |model_name|
    model_name.classify
  end
end

step 'I sign in as a user' do
  @current_user_role = FactoryGirl.create(:role)
  @current_user = FactoryGirl.create(:user,
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

step 'I have a role scoped to :model :string' do |model, identifier|
  scope_object =
    case model
    when 'Study' then Study.find_by(name: identifier)
    when 'Center' then Center.find_by(name: identifier)
    when 'Patient' then Patient.find_by(subject_id: identifier)
    end
  expect(scope_object).to be_present

  @current_user_role = FactoryGirl.create(:role)
  UserRole.create(
    user: @current_user,
    role: @current_user_role,
    scope_object: scope_object
  )
  user_role = @current_user.user_roles.where(role: @current_user_role).first
  expect(user_role).not_to be_nil
  expect(user_role.scope_object).to eq(scope_object)
end

step 'I sign in as a user with role scoped to :model :string' do |model, identifier|
  send('I sign in as a user')
  send('I have a role scoped to :model :string', model, identifier)
end

step 'I can :activity :subject' do |activity, subject|
  @current_user_role.add_permission(activity, subject)
end

step 'I cannot :activity :subject' do |activity, subject|
  expect(@current_user.can?(activity, subject)).to be_falsy
end

step 'I browse to the dashboard' do
  visit('/admin/dashboard')
end

step 'I browse to :string' do |path|
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

step 'I am redirected to patient :string' do |subject_id|
  @patient = Patient.where(subject_id: subject_id).first
  expect(@patient).not_to be_nil
  expect(page.current_path).to eq(admin_patient_path(@patient))
end

step 'I pry' do
  binding.pry
end

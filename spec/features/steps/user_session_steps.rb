placeholder :activity do
  activities = Ability::ACTIVITIES.values.flatten.uniq.join('|')
  match(/(#{activities})/, &:to_sym)
end

placeholder :subject do
  match(/([^ $\n]+)/) do |subject|
    subject.classify.constantize
  end
end

step 'I sign in as a user' do
  @current_user_role = FactoryGirl.create(:role)
  @current_user = FactoryGirl.create(:user,
                                     password: 'foobar',
                                     password_changed_at: Time.now,
                                     with_user_roles: [@current_user_role])
  visit('/users/sign_in')
  within('#new_user') do
    fill_in 'Username', with: @current_user.username
    fill_in 'Password', with: 'foobar'
  end
  click_button 'Sign in'
end

step 'I can :activity :subject' do |activity, subject|
  @current_user_role.add_permission(activity, subject)
end

step 'I browse to the dashboard' do
  visit('/admin/dashboard')
end

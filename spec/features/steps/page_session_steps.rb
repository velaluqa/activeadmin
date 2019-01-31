step 'I sign in as a user' do
  @current_user_role = FactoryGirl.create(:role)
  @current_user = FactoryGirl.create(:user,
                                     :changed_password,
                                     :with_keypair,
                                     name: 'Test User',
                                     username: 'testuser',
                                     password: 'password',
                                     password_changed_at: Time.now,
                                     with_user_roles: [@current_user_role])
  visit('/users/sign_in')
  within('#new_user') do
    validation_report_screenshot
    fill_in 'Username', with: 'testuser'
    validation_report_screenshot
    fill_in 'Password', with: 'password'
    validation_report_screenshot
  end
  click_button 'Sign in'
  expect(page).to have_content('Signed in successfully')
  validation_report_screenshot
end

step 'I sign in as a user with all permissions' do
  send('I sign in as a user')
  send('I have permission to perform all actions')
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

step 'I have permission to perform all actions' do
  abilities = Ability::ACTIVITIES.flat_map do |subject, val|
    val.flat_map do |action|
      next if action == :manage
      [action, subject.to_s.underscore].join('_').downcase
    end
  end.compact
  @current_user_role.abilities = abilities
  @current_user_role.save!
end

step 'I can :activity :subject' do |activity, subject|
  @current_user_role.add_permission(activity, subject)
end

step 'I cannot :activity :subject' do |activity, subject|
  @current_user_role.remove_permission(activity, subject)
  expect(@current_user.can?(activity, subject)).to be_falsy
end

step 'I browse to :string' do |path|
  visit(path)
end

step 'I browse to :admin_path' do |path|
  visit(path)
end

step 'I browse to last defined :model' do |model_name|
  model_name = model_name.classify
  record =
    case model_name
    when 'Study' then @study
    when 'Center' then @center
    when 'Patient' then @patient
    when 'Visit' then @visit
    when 'ImageSeries' then @image_series
    when 'Image' then @image
    when 'User' then @user
    when 'Role' then @role
    end
  path = Rails.application.routes.url_helpers.send("admin_#{model_name.singularize.underscore}_path", record)
  visit(path)
end

step 'I browse to :admin_path with:' do |path, parameters|
  path = URI.parse(path)
  path.query = URI.encode_www_form(parameters.to_a)
  visit(path.to_s)
end

step 'I see the unauthorized page' do
  expect(page).to have_content('Not Authorized')
  expect(page).to have_content('You are not authorized to perform this action!')
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
  expect(page).to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step 'I see :string within :string' do |content, locator|
  expect(page.find(locator)).to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step 'I don\'t see :string' do |content|
  expect(page).not_to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step 'I don\'t see :string within :string' do |content, locator|
  expect(page.find(locator)).not_to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step 'I am redirected to :admin_path' do |path|
  expect(page.current_path).to eq(path)
end

step 'I click link :string' do |locator|
  click_link(locator)
end

step 'I follow link :string' do |locator|
  page.click_link(locator)
end

step 'I click link :string in :string' do |locator, selector|
  within(selector) do
    click_link(locator)
  end
end

step 'I click :string in :string row' do |locator, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    td.click_link(locator)
  end
end

step 'I see :string in :string row' do |text, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    expect(td.text).to include(text)
  end
end

step 'I don\'t see :string in :string row' do |text, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    expect(td.text).not_to include(text)
  end
end

step 'I pry' do
  binding.pry
end

step 'I wait :number seconds' do |seconds|
  sleep(seconds.to_i)
end

step 'I wait for all jobs in :string queue' do |queue|
  available_workers =
    Dir['app/workers/**/*']
      .entries
      .map { |file| File.read(file).match(/class ([^\n]*)/).andand[1] }
      .compact
  if available_workers.include?(queue)
    queue.constantize.drain
  end
end

step 'I download zip file' do
  clear_downloads_js = "document.querySelector('downloads-manager').shadowRoot.querySelector('downloads-toolbar').shadowRoot.querySelector('button.clear-all').click()"
  download_count_js = "document.querySelector('downloads-manager').shadowRoot.querySelectorAll('downloads-item').length"
  no_downloads_el_js = "document.querySelector('downloads-manager').shadowRoot.querySelector('#no-downloads')"

  page.driver.browser.get('chrome://downloads/')
  ts = Time.now
  begin
    sleep(0.1)
    download_count = page.evaluate_script(download_count_js)
  end until Time.now - ts > Capybara.default_max_wait_time ||
            download_count == 1 || !sleep(0.1)
  expect(download_count).to eq(1)
  expect(page).to have_content(".zip\n")
  page.evaluate_script(clear_downloads_js)
  ts = Time.now
  begin
    no_downloads_el = page.evaluate_script(no_downloads_el_js)
  end until Time.now - ts > Capybara.default_max_wait_time ||
            !no_downloads_el[:hidden] || !sleep(0.1)
  expect(no_downloads_el[:hidden]).to be_falsy
end

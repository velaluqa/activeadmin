step 'I sign in as a user' do
  step('a test user with a test role')
  step('I browse to the dashboard')
  step('I see "You need to sign in"')
  step("I fill in \"Username\" with \"#{@current_user.username}\"")
  step("I fill in \"Password\" with \"#{@current_user.password}\"")
  step('I click "Sign in"')
  step('I see "Signed in successfully"')
end

step 'a test user with a test role' do
  @current_user_role = FactoryGirl.create(:role)
  @current_user =
    FactoryGirl.create(
      :user,
      :changed_password,
      :with_keypair,
      name: 'Test User',
      username: 'testuser',
      password: 'password',
      password_changed_at: Time.now,
      with_user_roles: [@current_user_role]
    )
end

step 'I sign in as user :string' do |username|
  step('I browse to the dashboard')
  step('I see "You need to sign in"')
  step("I fill in \"Username\" with \"#{username}\"")
  step('I fill in "Password" with "password"')
  step('I click "Sign in"')
  step('I see "Signed in successfully"')
end

step 'I sign in as a user with all permissions' do
  step('I sign in as a user')
  step('I have permission to perform all actions')
end

step 'I sign in as a user with role scoped to :string :string' do |model, identifier|
  step('I sign in as a user')
  step("I have a role scoped to #{model} \"#{identifier}}\"")
end

step 'I sign in as a user with role :string' do |role|
  step('I sign in as a user')
  step("I belong to role \"#{role}\"")
end

step 'I sign in as a user with role :string scoped to :string :string' do |role, model, identifier|
  step('I sign in as a user')
  step("I belong to role \"#{role}\" scoped to #{model} \"#{identifier}\"")
end

step 'I belong to role :string' do |role|
  step("user \"#{@current_user.username}\" belongs to role \"#{role}\"")
end

step 'I belong to role :string scoped to :string :string' do |role, model, identifier|
  step(
    "user \"#{@current_user.username}\" belongs to role \"#{role}\" scoped to #{
      model
    } \"#{identifier}\""
  )
end

step 'I have a role scoped to :string :string' do |model, identifier|
  @current_user_role = FactoryGirl.create(:role)
  step(
    "user \"#{@current_user.username}\" belongs to role \"#{
      @current_user_role.title
    }\" scoped to #{model} \"#{identifier}\""
  )
end

step 'I have permission to perform all actions' do
  abilities =
    Ability::ACTIVITIES.flat_map do |subject, val|
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
    when 'Study'
      @study
    when 'Center'
      @center
    when 'Patient'
      @patient
    when 'Visit'
      @visit
    when 'ImageSeries'
      @image_series
    when 'Image'
      @image
    when 'User'
      @user
    when 'Role'
      @role
    end
  path =
    Rails.application.routes.url_helpers.send(
      "admin_#{model_name.singularize.underscore}_path",
      record
    )
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

step "I don't see :string" do |content|
  expect(page).not_to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step "I don't see :string within :string" do |content, locator|
  expect(page.find(locator)).not_to have_content(content, normalize_ws: true)
  validation_report_screenshot
end

step 'I am redirected to :admin_path' do |path|
  expect(page.current_path).to eq(path)
end

step 'I click :string' do |locator|
  click_on(locator)
end

step 'I click link :string' do |locator|
  page.click_link(locator)
end

step 'I click link :string in :string' do |locator, selector|
  within(selector) { click_link(locator) }
end

step 'I click :string in :string row' do |locator, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    td.click_link(locator)
  end
end

# TODO: Make this more explicit by filtering specific column.
step 'I select row for :string' do |locator|
  selected = 0
  page.all("tr").each do |tr|
    next unless tr.text.include?(locator)

    selected += 1
    tr.find(".collection_selection").click
  end
  raise "expected to select at least one table row with #{locator.inspect}" unless selected > 0
  validation_report_screenshot
end

step 'I see a row with/for :string' do |str|
  found_rows = 0
  page.all("tr").each do |tr|
    found_rows += 1 if tr.text.include?(str)
  end
  expect(found_rows).to(be > 0, "expected to find at least one row with #{str.inspect}")
end

step 'I don\'t see a row with/for :string' do |str|
  found_rows = 0
  page.all("tr").each do |tr|
    found_rows += 1 if tr.text.include?(str)
  end
  expect(found_rows).to eq(0), "expected not to find a row with #{str.inspect}"
end

step 'I see a column :string' do |name|
  found_columns = 0
  page.all("table th").map do |th|
    found_columns += 1 if th.text.include?(name)
  end
  expect(found_columns).to be > 0, "expected to find at least one table column with #{name.inspect}"
end

step 'I don\'t see a column :string' do |name|
  found_columns = 0
  page.all("table th").map do |th|
    found_columns += 1 if th.text.include?(name)
  end
  expect(found_columns).to eq(0), "expected not to find a table column with #{name.inspect}"
end

step 'I see a row with the following columns:' do |values|
  found_rows = 0

  page.all("table").each do |table|
    columns = table.all("thead th").map(&:text)
    table.all("tbody tr").each do |tr|
      found_columns = values.to_a.map do |key, expected_value|
        next unless columns.include?(key)

        index = columns.index(key)
        column_value = tr.all("td")[index].text
        column_value.include?(expected_value)
      end

      found_rows += 1 if found_columns.all?
    end
  end

  expect(found_rows).to(be > 0, "expected to find at least one table row with the respective values (#{values.to_a.map { |pair| pair.join(": ") }.join(", ")})")
end

step 'I see a/an :string link/button in row for :string' do |link, selector|
  page.all('tr').each do |tr|
    next unless tr.text.include?(selector)

    links = tr.all('a, button').map(&:text)
    expect(links).to include(link), "expected to see a #{link.inspect} link or button in row for #{selector.inspect}"
  end
end

step 'I don\'t see a/an :string link/button in row for :string' do |link, selector|
  page.all('tr').each do |tr|
    next unless tr.text.include?(selector)

    links = tr.all('a, button').map(&:text)
    expect(links).not_to include(link), "expected not to see a #{link.inspect} link or button in row for #{selector.inspect}"
  end
end

step 'I see a row with/for :string and/with the following columns:' do |locator, values|
  found_rows = 0
  page.all("table").each do |table|
    columns = table.all("thead th").map(&:text)
    table.all("tbody tr").each do |tr|
      next unless tr.text.include?(locator)

      found_rows += 1
      values.to_h.each_pair do |key, expected_value|
        expect(columns).to include(key), "expected table columns (#{columns.join(', ')}) to include #{key.inspect}"

        index = columns.index(key)
        column_value = tr.all("td")[index].text

        expect(column_value)
          .to eq(expected_value), "expected #{column_value.inspect} to equal #{expected_value.inspect} in column #{key.inspect}"
      end
    end
  end

  expect(found_rows).to(be > 0, "expected to find at least one table row with #{locator.inspect} and the respective values")
end

step 'I don\'t see a row with/for :string and/with the following columns:' do |locator, values|
  found_rows = 0
  page.all("table").each do |table|
    columns = table.all("thead th").map(&:text)
    table.all("tbody tr").each do |tr|
      next unless tr.text.include?(locator)

      found_columns = values.to_a.map do |key, expected_value|
        next unless columns.include?(key)

        index = columns.index(key)
        column_value = tr.all("td")[index].text
        column_value.include?(expected_value)
      end

      found_rows += 1 if found_columns.all?
    end
  end
  expect(found_rows).to eq(0), "expected not to find a row with #{locator.inspect} and the respective values (#{values.to_a.map { |pair| pair.join(": ") }.join(", ")})"
end

step 'I see :string in :string row' do |text, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    expect(td.text).to include(text)
  end
  validation_report_screenshot
end

step "I don't see :string in :string row" do |text, row_content|
  page.all('tr').each do |td|
    next unless td.text.include?(row_content)
    expect(td.text).not_to include(text)
  end
  validation_report_screenshot
end

step 'I pry' do
  binding.pry
end

step 'I wait :number seconds' do |seconds|
  sleep(seconds.to_i)
end

step 'I wait for all jobs in :string queue' do |queue|
  available_workers =
    Dir['app/workers/**/*'].entries.map do |file|
      File.read(file).match(/class ([^\n]*)/).andand[1]
    end.compact
  queue.constantize.drain if available_workers.include?(queue)
end

step 'I download zip file' do
  clear_downloads_js =
    "document.querySelector('downloads-manager').shadowRoot.querySelector('downloads-toolbar').shadowRoot.querySelector('button.clear-all').click()"
  download_count_js =
    "document.querySelector('downloads-manager').shadowRoot.querySelectorAll('downloads-item').length"
  no_downloads_el_js =
    "document.querySelector('downloads-manager').shadowRoot.querySelector('#no-downloads')"

  page.driver.browser.get('chrome://downloads/')
  ts = Time.now

  begin
    download_count = page.evaluate_script(download_count_js)
  rescue e
    puts e.inspect
  end
  until (Time.now - ts) > Capybara.default_max_wait_time || download_count == 1 || !sleep(0.1)
    begin
      download_count = page.evaluate_script(download_count_js)
    rescue e
      puts e.inspect
    end
  end
  expect(download_count).to eq(1)
  expect(page).to have_content(".zip\n")
  validation_report_screenshot
  page.evaluate_script(clear_downloads_js)
  ts = Time.now
  begin
    no_downloads_el = page.evaluate_script(no_downloads_el_js)
  rescue e
    puts e.inspect
  end
  until Time.now - ts > Capybara.default_max_wait_time || !no_downloads_el[:hidden] || !sleep(0.1)
    begin
      no_downloads_el = page.evaluate_script(no_downloads_el_js)
    rescue e
      puts e.inspect
    end
  end
  expect(no_downloads_el[:hidden]).to be_falsy
end

step 'another window is opened' do
  other_windows =
    (page.driver.browser.window_handles - [page.driver.browser.window_handle])
  handle = other_windows.last
  expect(handle).not_to be_nil
  page.driver.browser.switch_to.window(handle)
end

step 'I switch to the window :string' do |window_name|
  handle = page.driver.find_window(window_name)
  page.driver.browser.switch_to.window(handle)
end

step 'I close the current window' do
  page.driver.browser.switch_to.window(page.driver.browser.window_handle)
  page.driver.browser.close
end

step 'I close the window :string' do |window_name|
  handle = page.driver.browser.window_handle
  send('I switch to the window :string', window_name)
  send('I close the current window')
  page.driver.browser.switch_to.window(handle)
end

step 'I confirm popup' do
  page.driver.browser.switch_to.alert.accept
end

step 'I confirm alert' do
  page.driver.browser.switch_to.alert.accept
end

step 'I dismiss popup' do
  page.driver.browser.switch_to.alert.dismiss
end

step 'I debug' do
  debugger
end

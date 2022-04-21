step 'another window/tab is opened' do
  other_windows =
    (page.driver.browser.window_handles - [page.driver.browser.window_handle])
  handle = other_windows.last
  expect(handle).not_to be_nil
  page.driver.browser.switch_to.window(handle)
end

step 'I close the current window/tab' do
  handle = page.driver.current_window_handle
  page.driver.close_window(handle)

  handle = page.driver.browser.window_handles.last
  expect(handle).not_to be_nil
  page.driver.browser.switch_to.window(handle)
end

step 'I switch to the window :string' do |window_name|
  handle = page.driver.find_window(window_name)
  page.driver.browser.switch_to.window(handle)
end

# step 'I close the current window' do
#   page.driver.browser.switch_to.window(page.driver.browser.window_handle)
#   page.driver.browser.close
# end

step 'I close the window :string' do |window_name|
  handle = page.driver.browser.window_handle
  send('I switch to the window :string', window_name)
  send('I close the current window')
  page.driver.browser.switch_to.window(handle)
end

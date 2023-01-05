module WaitUntil
  def wait_until(max_wait_time = Capybara.default_max_wait_time)
    Timeout.timeout(max_wait_time) do
      sleep(0.2) until yield
    end
  rescue
    # noop
  end
end

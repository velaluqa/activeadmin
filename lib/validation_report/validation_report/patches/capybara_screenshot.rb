Capybara::Screenshot.append_random = true

module Capybara
  module Screenshot
    def self.screenshot(*args)
      saver = new_saver(Capybara, Capybara.page, false, *args)
      saver.save
      saver.screenshot_path
    end
  end
end

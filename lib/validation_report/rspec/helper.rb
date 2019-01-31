require 'fileutils'

module ValidationReport
  module RSpec
    module Helper
      def validation_report_screenshot
        image_path = Capybara::Screenshot.screenshot
        FileUtils.mv(
          image_path,
          ValidationReport.tmp_path.join(File.basename(image_path))
        )
      end
    end
  end
end

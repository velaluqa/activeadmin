require 'fileutils'

module ValidationReport
  module RSpec
    module Helper
      def validation_report_screenshot
        image_path = make_screenshot
        ValidationReport.attach_screenshot(image_path)
      end

      private

      def make_screenshot
        image_path = Capybara::Screenshot.screenshot
        target_path = ValidationReport.tmp_path.join(File.basename(image_path))
        FileUtils.mv(image_path, target_path)
        target_path
      end
    end
  end
end

require 'fileutils'

module ValidationReport
  module RSpec
    module Helper
      def validation_report_screenshot
        if ValidationReport.enabled?
          image_path = make_screenshot
          ValidationReport.attach_screenshot(image_path)
        end
      end

      private

      def make_screenshot
        image_path = Capybara.current_session.save_screenshot
        target_path = ValidationReport.tmp_path.join(File.basename(image_path))
        FileUtils.mv(image_path, target_path)
        File.basename(target_path)
      end
    end
  end
end

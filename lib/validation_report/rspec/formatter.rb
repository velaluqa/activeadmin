RSpec::Support.require_rspec_core 'formatters/base_text_formatter'

module ValidationReport
  module RSpec
    class Formatter < ::RSpec::Core::Formatters::ProgressFormatter
      ::RSpec::Core::Formatters.register self, :start, :stop

      def start(_notification)
        ValidationReport.setup
      end

      def stop(_notification)
        ValidationReport.generate(_notification.notifications)
      end
    end
  end
end

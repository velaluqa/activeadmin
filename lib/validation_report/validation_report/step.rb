# coding: utf-8
module ValidationReport
  class Step
    attr_reader :name
    attr_reader :substeps_and_screenshots
    attr_accessor :parent_step, :turnip_step, :scenario

    def initialize(label:, source_location:)
      @name = label
      @source_location = source_location
      @substeps_and_screenshots = []
      @passed = false
      @scenario = nil
    end

    def add_substep(step)
      step.parent_step = self
      @substeps_and_screenshots << step
    end

    def add_screenshot(screenshot)
      @substeps_and_screenshots << screenshot
    end

    def mark_as_passed
      @passed = true
    end

    def passed?
      @passed
    end

    def turnip_argument
      @turnip_step&.argument
    end

    def table
      turnip_argument if turnip_argument.is_a?(Turnip::Table)
    end

    def docstring
      turnip_argument if turnip_argument.is_a?(String)
    end

    # @return [String]
    def report_html_row(indent_level: 0)
      step_cell = "#{'→' * indent_level} #{name}"
      if table
        step_cell << "<br/><table class=\"step-parameters\">"
        table.to_a.each do |row|
          step_cell << '<tr><td>'
          step_cell << row.join('</td><td>')
          step_cell << '</td></tr>'
        end
        step_cell << "</table>"
      end
      if docstring
        step_cell << '<br/><pre>'
        step_cell << docstring
        step_cell << '</pre>'
      end
      screenshots = substeps_and_screenshots.select { |s| s.is_a?(Screenshot) }
      substeps = substeps_and_screenshots.select { |s| s.is_a?(Step) }
      if screenshots.length > 1
        throw "There should only be one screenshot per step."
      elsif screenshots.length > 0
        screenshot_cell = "<a href=\"#{screenshots.first.path}\" target=\"_blank\">Open</a>"
      end
      html = "<tr>\n" +
        [
          "<td></td>\n",
          "<td>#{step_cell}</td>\n",
          "<td>#{screenshot_cell}</td>\n",
          @passed ? "<td class=\"passed\">✓</td>" : "<td class=\"failed\">✕</td>",
          "<td></td>\n",
          "<td></td>\n",
          "<td></td>\n"
        ].join +
        "</tr>\n" +
        substeps.map do |substep|
          substep.report_html_row(indent_level: indent_level + 1)
        end.join
      unless @passed
        html << "<tr>\n" +
                [
                  "<td></td>\n",
                  "<td cellspan=\"3\"><i>Further steps omitted, if any</i></td>\n",
                  "<td></td>\n",
                  "<td></td>\n",
                  "<td></td>\n"
                ].join +
                "</tr>\n"
      end
      html
    end

    # @return [String] source code of step definition
    def source_code
      @source_code ||= begin
        f = File.new(@source_location.first, 'r')
        i = 1
        while i < @source_location.last
          f.gets
          i += 1
        end
        step_source = f.readline
        # Read until beginning of next step definition or EOF
        while true
          begin
            line = f.readline
          rescue EOFError
            break
          end
          if line !~ /\Astep/
            step_source += line
          else
            break
          end
        end
        f.close
        step_source.strip
      end
    end

    # @return [Gem::Version, Symbol] change version or :unreleased
    def change_version
      @change_version ||= calculate_change_version
    end

    private
    # This is a private method, because return statements within a
    # begin ... end memoize block voids memoization
    def calculate_change_version
      return :unreleased unless @source_location

      versions = ValidationReport.versions
      step_file = `git show #{versions.first}:#{@source_location.first} 2>&1`
      unless step_file.include?(source_code)
        return :unreleased
      end

      1.upto(versions.length - 1) do |i|
        version = versions[i]
        step_file = `git show #{version}:#{@source_location.first} 2>&1`
        unless step_file.include?(source_code)
          return versions[i - 1]
        end
      end

      return versions.last
    end
  end
end

module ValidationReport
  class Step
    attr_accessor :parent_step, :turnip_step
    attr_reader :substeps_and_screenshots

    def initialize(label:, source_location:)
      @label = label
      @source_location = source_location
      @substeps_and_screenshots = []
    end

    def add_substep(step)
      step.parent_step = self
      @substeps_and_screenshots << step
    end

    def add_screenshot(screenshot)
      @substeps_and_screenshots << screenshot
    end

    def table
      if @turnip_step.present?
        @turnip_step.argument if @turnip_step.argument.is_a?(Turnip::Table)
      end
    end

    def docstring
      if @turnip_step.present?
        @turnip_step.argument if @turnip_step.argument.is_a?(String)
      end
    end

    # @return [String] markdown section
    def report_markdown(indent_level:)
      md = "\n#{'#' * indent_level} #{@label}\n"
      if table
        md << "\n"
        table.to_a.each do |row|
          md << "| #{row.join(' | ')} |\n"
        end
      end
      if docstring
        md << "\n```\n"
        md << step.docstring
        md << "\n```\n"
      end
      v = last_change_version
      if v == :unreleased
        md << "\nStep definition unreleased\n"
      else
        md << "\nStep definition changed with version #{last_change_version}\n"
      end
      substeps_and_screenshots.each do |substep_or_screenshot|
        if substep_or_screenshot.is_a?(Step)
          md << substep_or_screenshot.report_markdown(
            indent_level: indent_level + 1
          )
        elsif substep_or_screenshot.is_a?(Screenshot)
          md << "\n![](#{substep_or_screenshot.path})\n"
        end
      end
      md
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

    # @return [Gem::Version, Symbol] last change version or :unreleased
    def last_change_version
      @last_change_version ||= calculate_last_change_version
    end

    private
    # This is a private method, because return statements within a
    # begin ... end memoize block voids memoization
    def calculate_last_change_version
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

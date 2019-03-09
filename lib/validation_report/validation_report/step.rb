module ValidationReport
  class Step
    attr_accessor :parent_step, :turnip_step
    attr_reader :substeps_and_screenshots

    def initialize(label:, source_file_path:)
      @label = label
      @source_file_path = source_file_path
      @substeps_and_screenshots = []
    end

    def add_substep(step)
      step.parent_step = self
      @substeps_and_screenshots << step
    end

    def add_screenshot(screenshot)
      @substeps_and_screenshots << screenshot
    end

    def text
      if @turnip_step.present?
        @text ||= @turnip_step.keyword + @turnip_step.text
      end
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
      md << "\nStep definition changed with version x.x.x\n"
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
  end
end

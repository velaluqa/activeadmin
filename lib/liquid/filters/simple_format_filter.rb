module Liquid
  module Filters
    module SimpleFormatFilter # :nodoc:
      class Linker # :nodoc:
        include ActionView::Helpers::TextHelper
      end

      def to_simple_format(target, options = {})
        target_with_linebreak = target.gsub('\n', "\n")
        Linker
          .new
          .simple_format(target_with_linebreak, {}, options.symbolize_keys)
          .delete("\n")
      end
    end
  end
end

Liquid::Template.register_filter(Liquid::Filters::SimpleFormatFilter)

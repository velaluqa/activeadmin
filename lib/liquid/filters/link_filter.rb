module Liquid
  module Filters
    module LinkFilter # :nodoc:
      class Linker # :nodoc:
        include ApplicationHelper
        include ActionView::Helpers::UrlHelper

        def link(target, text)
          case target
          when Liquid::Rails::Drop then
            target = admin_url_for(target.send(:object))
            text ||= target.to_s
          when String then
            target = target
            text ||= target
          else raise 'Unknown type of object linking to'
          end
          link_to(text, target)
        end
      end

      def link(target, text = nil)
        Linker.new.link(target, text)
      end
    end
  end
end

Liquid::Template.register_filter(Liquid::Filters::LinkFilter)

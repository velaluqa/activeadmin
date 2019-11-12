module ActiveAdmin
  module Views
    class EricaSiteTitle < Component
      def build(namespace)
        super(id: 'site_title')
        @namespace = namespace

        site_title_content
      end

      def site_title_image?
        ERICA.site_title_image.present?
      end

      def narrow_site_title_image?
        ERICA.narrow_site_title_image.present?
      end

      def narrow_site_title?
        ERICA.narrow_site_title.present?
      end

      private

      def site_title_content
        if site_title_image?
          div(class: 'wide') do
            title_image
          end
          div(class: 'narrow') do
            if narrow_site_title_image?
              narrow_title_image
            else
              span(class: 'menu bars icon')
            end
          end
        else
          div(class: 'wide') do
            title_text
          end
          div(class: 'narrow') do
            if narrow_site_title?
              narrow_title_text
            else
              span(class: 'menu bars icon')
            end
          end
        end
      end

      def title_text
        helpers.render_or_call_method_or_proc_on(self, ERICA.site_title)
      end

      def narrow_title_text
        helpers.render_or_call_method_or_proc_on(self, ERICA.narrow_site_title)
      end

      def title_image
        path = helpers.render_or_call_method_or_proc_on(self, ERICA.site_title_image)
        helpers.image_tag(path, id: 'site_title_image', alt: title_text)
      end

      def narrow_title_image
        path = helpers.render_or_call_method_or_proc_on(self, ERICA.narrow_site_title_image)
        helpers.image_tag(path, id: 'site_title_image', alt: title_text)
      end
    end
  end
end

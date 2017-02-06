module Pharmtrace
  module ActiveAdmin
    # Override the header of ActiveAdmin to render some ERICA specific information.
    class Header < ::ActiveAdmin::Component
      def build(namespace, menu)
        super(id: "header")

        @namespace = namespace
        @menu = menu
        @utility_menu = @namespace.fetch_menu(:utility_navigation)

        build_site_title
        div class: 'navigation-wrapper' do
          div class: 'growing-wrapper' do
            if session[:selected_study_name].present?
              ul class: 'tabs study-selection' do
                li id: 'study-selection' do
                  text = "Study: #{session[:selected_study_name]}"
                  link_to(text, admin_study_path(id: session[:selected_study_id]))
                end
              end
            end
            build_global_navigation
            build_utility_navigation
          end
        end
      end

      def build_site_title
        div class: 'title-wrapper' do
          insert_tag(view_factory.site_title, @namespace)
        end
      end

      def build_global_navigation
        insert_tag(
          view_factory.global_navigation,
          @menu,
          class: 'header-item tabs'
        )
      end

      def build_utility_navigation
        insert_tag(
          view_factory.utility_navigation,
          @utility_menu,
          id: 'utility_nav',
          class: 'header-item tabs'
        )
      end
    end
  end
end

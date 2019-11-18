# coding: utf-8
module ActiveAdmin
  module Views
    # Overriding ActiveAdmin defaults.
    class EricaHeader < Component
      def build(namespace, menu)
        super(id: 'header')

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
        div(class: 'header-item tabs') do
          insert_tag(
            view_factory.global_navigation,
            @menu
          )
          insert_tag(
            view_factory.utility_navigation,
            @utility_menu,
            class: 'second'
          )
        end
      end

      def build_utility_navigation
        div(id: 'utility_nav') do
          input(type: 'checkbox', id: 'toggle-menu')
          label(for: 'toggle-menu')
          label('Show Always', for: 'toggle-menu', class: 'text')
        end
      end
    end
  end
end

module ActiveAdmin
  module Views
    class EricaTitleBar < Component
      def build(title, action_items)
        super(id: 'title_bar')
        @title = title
        @action_items = action_items
        build_titlebar_left
        build_titlebar_right
      end

      private

      def build_titlebar_left
        class_name = session[:selected_study_name].present? && 'with_selected_study'
        div id: 'titlebar_left', class: class_name do
          if session[:selected_study_name].present?
            div(id: 'selected_study') do
              text_node link_to "Selected Study: #{session[:selected_study_name]}", admin_study_path(id: session[:selected_study_id])
            end
          end
          build_breadcrumb
          build_title_tag
        end
      end

      def build_titlebar_right
        div id: 'titlebar_right' do
          build_action_items
          add_filter_toggle_button if has_sidebar_section?("filters")
          add_cart_toggle_button if has_sidebar_section?("viewer_cart")
          add_hideable_column_toggle_button if has_sidebar_section?("hideable_columns")
        end
      end

      def has_sidebar_section?(name)
        active_admin_config
          .sidebar_sections_for(controller.action_name, self)
          .map(&:name)
          .include?(name)
      end

      def build_breadcrumb(separator = '/')
        breadcrumb_config = active_admin_config && active_admin_config.breadcrumb

        links = if breadcrumb_config.is_a?(Proc)
                  instance_exec(controller, &active_admin_config.breadcrumb)
                elsif breadcrumb_config.present?
                  breadcrumb_links
                end
        Array(links).reject! { |link| link.include?('"/admin"') }
        return unless links.present? && links.is_a?(::Array)
        span class: 'breadcrumb' do
          links.each do |link|
            text_node link
            span(separator, class: 'breadcrumb_sep')
          end
        end
      end

      def build_title_tag
        h2(@title, id: 'page_title')
      end

      def build_action_items
        insert_tag(view_factory.action_items, @action_items)
      end
 
      def add_filter_toggle_button
        filter_count = (params[:q] || {}).values.reject(&:blank?).length
        filter_label = filter_count > 0 ? "View Filters (#{filter_count})" : "View Filters"
        span class: "action_item filter" do
          a filter_label, href: "#", "data-toggle-sidebar-sections" => "filters,search_status"
        end
      end

      def add_cart_toggle_button
        cart_count = session[:viewer_cart].present? ? session[:viewer_cart].length : 0
        cart_label = cart_count > 0 ? "View Cart (#{cart_count})" : "View Cart"
        span class: "action_item cart" do
          a cart_label, href: "#", "data-toggle-sidebar-sections" => "viewer_cart"
        end
      end

      def add_hideable_column_toggle_button
        span class: "action_item hideable_column" do
          a "View Columns", href: "#", "data-toggle-sidebar-sections" => "hideable_columns"
        end
      end
    end
  end
end



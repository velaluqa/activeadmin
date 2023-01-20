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
          #This feels illegal I would like to know how to do this better
          if  params[:controller] == 'admin/studies' || params[:controller] == 'admin/centers' || params[:controller] == 'admin/patients' || params[:controller] == 'admin/image_series' || params[:controller] == 'admin/visits' || params[:controller] == 'admin/users'
            add_filter_toggle_button
            add_cart_toggle_button
          end
        end
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
          span class: "action_item filter" do
            a "View Filters", href: "#", id: 'filter_toggle'
          end
        end

      def add_cart_toggle_button
        span class: "action_item cart" do
          if session[:viewer_cart].present?
            a "View Cart (#{session[:viewer_cart].length})", id: 'cart_toggle',href: "#"
          else
            a "View Cart", id: 'cart_toggle',href: "#"
          end
        end
      end
    end
  end
end



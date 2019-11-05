module ActiveAdmin
  module ViewerCartMixin
    module DSL
      def viewer_cartable(resource_type)
        sidebar :viewer_cart, only: :index do
          cart = session[:viewer_cart] || []

          render partial: 'admin/shared/viewer_cart', locals: { cart: cart }
        end

        batch_action :add_to_viewer_cart do |selection|
          session[:viewer_cart] ||= []

          selection.each do |id|
            session[:viewer_cart] << { type: resource_type, id: id.to_i }
          end

          flash[:notice] = "#{selection.length} #{ActiveSupport::Inflector.humanize(resource_type)} added to viewer cart."
          redirect_back(fallback_location: admin_viewer_cart_path)
        end
      end
    end
  end
end

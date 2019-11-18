ActiveAdmin.register_page 'Viewer Cart' do
  menu(priority: 10, parent: 'immediate')

  content do
    cart = session[:viewer_cart] || []

    cart = cart.map do |cart_item|
      begin
        resource = case cart_item[:type]
                   when :image_series then ImageSeries.find(cart_item[:id])
                   when :visit then Visit.find(cart_item[:id])
                   when :patient then Patient.find(cart_item[:id])
                   when :center then Center.find(cart_item[:id])
                   when :study then Study.find(cart_item[:id])
                   end
      rescue ActiveRecord::RecordNotFound => e
        resource = nil
      end

      if resource.nil?
        nil
      else
        cart_item[:resource] = resource
        cart_item
      end
    end

    cart = cart.reject(&:nil?)

    session[:viewer_cart] = cart.map do |cart_item|
      { type: cart_item[:type], id: cart_item[:id] }
    end

    render 'admin/viewer_cart/viewer_cart', cart: cart
  end

  action_item :start_viewer, unless: -> { session[:viewer_cart].empty? } do
    link_to('Start Viewer', admin_viewer_cart_start_path)
  end

  action_item :clear_cart, unless: -> { session[:viewer_cart].empty? } do
    link_to('Clear Cart', admin_viewer_cart_clear_path, :'data-confirm' => 'This will remove all items from the cart. Are you sure?')
  end

  page_action :empty, method: :get do
    session[:viewer_cart] = []
    redirect_back(fallback_location: admin_viewer_cart_path)
  end
  page_action :clear, method: :get do
    session[:viewer_cart] = []

    redirect_to({ action: :index }, notice: 'Viewer cart cleared.')
  end
  page_action :remove, method: :get do
    type = params[:type]
    id = params[:id]

    if type && id && session[:viewer_cart]
      type = type.to_sym
      id = id.to_i

      session[:viewer_cart] = session[:viewer_cart].reject { |cart_item| cart_item[:type] == type && cart_item[:id] == id }
    end

    redirect_to({ action: :index }, notice: 'Item removed from cart.')
  end

  page_action :start, method: :get do
    current_user.ensure_authentication_token!

    if session[:viewer_cart].nil?
      flash[:error] = 'Your viewer cart is empty.'
      redirect_to action: :index
      return
    end

    @wado_query_urls = session[:viewer_cart].map do |item|
      case item[:type]
      when :image_series then wado_query_image_series_url(item[:id], format: :xml, authentication_token: current_user.authentication_token)
      when :visit then wado_query_visit_url(item[:id], format: :xml, authentication_token: current_user.authentication_token)
      when :patient then wado_query_patient_url(item[:id], format: :xml, authentication_token: current_user.authentication_token)
      when :center then wado_query_center_url(item[:id], format: :xml, authentication_token: current_user.authentication_token)
      when :study then wado_query_study_url(item[:id], format: :xml, authentication_token: current_user.authentication_token)
      end
    end
    @wado_query_urls.reject!(&:nil?)

    send_data(
      render_to_string('admin/shared/viewer_weasis.jnpl', layout: false),
      type: 'application/x-java-jnlp-file',
      filename: 'viewer.jnlp',
      disposition: 'attachment'
    )
  end
end
